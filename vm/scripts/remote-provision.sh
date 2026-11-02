#!/usr/bin/env bash
# remote-provision.sh — runs INSIDE the guest (invoked by provision.sh
# over SSH as ctfbuilder, with sudo). Native build: real Apache + PHP +
# SQLite, no Docker. Entirely self-contained (every app file embedded
# below) so this one script rebuilds the box from nothing but a base
# Ubuntu cloud image. Idempotent.
set -euo pipefail

: "${RELEASE_SECRET:?RELEASE_SECRET must be passed in (never hardcode it here -- this script is public)}"
MCURIE_PASSWORD="librarian123"   # same creds disclosed as the web app's default login -- credential reuse, by design

echo "== Staging /opt (paths the app's own PHP expects) =="
sudo mkdir -p /opt

sudo tee /opt/generate_flags.php >/dev/null <<'PHP_EOF'
<?php
define('BOX_ID', 'beginner-reading-room');

function flag_for(string $secret, int $n): string {
    $digest = hash_hmac('sha256', BOX_ID . ':' . $n, $secret);
    return 'HLC{' . substr($digest, 0, 10) . '}';
}
PHP_EOF

sudo tee /opt/schema.sql >/dev/null <<'SQL_EOF'
CREATE TABLE books (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    cover_image TEXT NOT NULL
);

CREATE TABLE staff (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    password TEXT NOT NULL
);

CREATE TABLE staff_notes (
    id INTEGER PRIMARY KEY,
    note TEXT NOT NULL,
    passphrase TEXT NOT NULL
);
SQL_EOF

sudo tee /opt/make_covers.php >/dev/null <<'PHP_EOF'
<?php
$dir = '/var/www/html/images';
$covers = [
    'quiet_archivist.jpg' => [60, 60, 90],
    'ledgers_of_dust.jpg' => [90, 70, 40],
    'ferrymans_toll.jpg' => [30, 30, 40],
];
foreach ($covers as $file => [$r, $g, $b]) {
    $im = imagecreatetruecolor(400, 300);
    imagefill($im, 0, 0, imagecolorallocate($im, $r, $g, $b));
    for ($i = 0; $i < 12; $i++) {
        imagesetpixel($im, rand(0, 399), rand(0, 299), imagecolorallocate($im, rand(0,255), rand(0,255), rand(0,255)));
    }
    imagejpeg($im, "$dir/$file", 90);
    imagedestroy($im);
}
echo "Covers generated.\n";
PHP_EOF

sudo mkdir -p /opt/db
sudo tee /opt/db/seed.php >/dev/null <<'PHP_EOF'
<?php
require_once '/opt/generate_flags.php';

$secret = getenv('CTF_SECRET');
if (!$secret) { fwrite(STDERR, "CTF_SECRET not set\n"); exit(1); }

$dbPath = '/var/www/html/data/library.db';
if (file_exists($dbPath)) unlink($dbPath);

$pdo = new PDO('sqlite:' . $dbPath);
$pdo->exec(file_get_contents('/opt/schema.sql'));

$flag4 = flag_for($secret, 4);
$flag6 = flag_for($secret, 6);
$flag8 = flag_for($secret, 8);

$stego_passphrase = 'InkAndIvy22';

$pdo->exec("INSERT INTO books (title, author, cover_image) VALUES
    ('The Quiet Archivist', 'R. Okafor', 'quiet_archivist.jpg'),
    ('Ledgers of Dust', 'M. Curie-Hall', 'ledgers_of_dust.jpg'),
    ('The Ferryman''s Toll', 'Unknown', 'ferrymans_toll.jpg')");

$admin_pw = bin2hex(random_bytes(16));
$pdo->exec("INSERT INTO staff (id, username, password) VALUES (1, 'admin', " . $pdo->quote($admin_pw) . ")");
$pdo->exec("INSERT INTO staff (id, username, password) VALUES (2, 'librarian', 'librarian123')");

$stmt = $pdo->prepare("INSERT INTO staff_notes (note, passphrase) VALUES (?, ?)");
$stmt->execute([$flag6, $stego_passphrase]);

file_put_contents('/var/www/html/backup/catalog_backup.sql.txt',
    "-- leftover export, scheduled for deletion, nobody did\n" .
    "-- dumped: library.db -> books table\n" .
    "INSERT INTO books VALUES (1,'The Quiet Archivist','R. Okafor','quiet_archivist.jpg');\n" .
    "-- ops note left in by mistake: $flag4\n"
);

file_put_contents('/tmp/flag8_plain.txt', $flag8);
$esc_pass = escapeshellarg($stego_passphrase);
exec("steghide embed -cf /var/www/html/images/ledgers_of_dust.jpg -ef /tmp/flag8_plain.txt -p $esc_pass -f 2>&1", $out, $rc);
unlink('/tmp/flag8_plain.txt');
if ($rc !== 0) { fwrite(STDERR, "steghide embed failed: " . implode("\n", $out) . "\n"); exit(1); }

chown($dbPath, 'www-data');
echo "Seed complete.\n";
PHP_EOF

echo "== Laying out the app under /var/www/html =="
sudo rm -rf /var/www/html
sudo mkdir -p /var/www/html/staff /var/www/html/catalog /var/www/html/backup /var/www/html/uploads /var/www/html/images /var/www/html/data

sudo tee /var/www/html/index.php >/dev/null <<'PHP_EOF'
<?php require_once '/opt/generate_flags.php'; $secret = getenv('CTF_SECRET'); ?>
<!-- Halcyon Reading Room internal catalogue -- migrated from the old
     intranet in a hurry. -->
<!-- <?= flag_for($secret, 1) ?> -->
<!DOCTYPE html>
<html>
<head><title>Halcyon Reading Room</title></head>
<body>
<h1>Halcyon Reading Room</h1>
<p>Internal catalogue and lending desk, migrated from the old intranet.
Staff: use the <a href="staff/login.php">staff login</a>. Everyone else,
browse the <a href="catalog/search.php">catalog search</a>.</p>
</body>
</html>
PHP_EOF

sudo tee /var/www/html/staff/login.php >/dev/null <<'PHP_EOF'
<?php
session_start();
require_once '/opt/generate_flags.php';
$secret = getenv('CTF_SECRET');
$db = new PDO('sqlite:/var/www/html/data/library.db');
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $u = $_POST['username'] ?? '';
    $p = $_POST['password'] ?? '';
    $query = "SELECT * FROM staff WHERE username = '$u' AND password = '$p' LIMIT 1";
    $row = null;
    try {
        $stmt = $db->query($query);
        $row = $stmt ? $stmt->fetch(PDO::FETCH_ASSOC) : null;
    } catch (Exception $e) {
        $error = "Database error.";
    }
    if ($row) {
        $_SESSION['db_username'] = $row['username'];
        setcookie('role', $row['username'] === 'admin' ? 'admin' : 'staff', 0, '/');
        header('Location: dashboard.php');
        exit;
    } else {
        $error = 'Invalid credentials.';
    }
}
?>
<!DOCTYPE html>
<html>
<head><title>Staff Login</title></head>
<body>
<h2>Halcyon Reading Room — Staff Login</h2>
<?php if ($error): ?><p style="color:red"><?= htmlspecialchars($error) ?></p><?php endif; ?>
<form method="post">
  Username: <input type="text" name="username"><br>
  Password: <input type="password" name="password"><br>
  <button type="submit">Log in</button>
</form>
</body>
</html>
PHP_EOF

sudo tee /var/www/html/staff/dashboard.php >/dev/null <<'PHP_EOF'
<?php
session_start();
require_once '/opt/generate_flags.php';
$secret = getenv('CTF_SECRET');
if (!isset($_SESSION['db_username'])) {
    header('Location: login.php');
    exit;
}
$role = $_COOKIE['role'] ?? 'staff';
?>
<!DOCTYPE html>
<html>
<head><title>Staff Dashboard</title></head>
<body>
<h2>Staff Dashboard</h2>
<p>Logged in as: <?= htmlspecialchars($_SESSION['db_username']) ?></p>
<?php if ($role === 'admin'): ?>
  <p>Welcome back, administrator.</p>
  <p><?= flag_for($secret, 3) ?></p>
<?php else: ?>
  <p>Staff view. Nothing administrative here. (Hint: dashboards sometimes
  trust more than they should.)</p>
  <p><?= flag_for($secret, 2) ?></p>
<?php endif; ?>
<p>See also the <a href="panel.php">admin panel</a> (admin only, for real).</p>
</body>
</html>
PHP_EOF

sudo tee /var/www/html/staff/panel.php >/dev/null <<'PHP_EOF'
<?php
session_start();
require_once '/opt/generate_flags.php';
$secret = getenv('CTF_SECRET');
if (($_SESSION['db_username'] ?? '') !== 'admin') {
    http_response_code(403);
    echo "<h2>403 — administrators only</h2><p>Editing a cookie won't get you in here.</p>";
    exit;
}
?>
<!DOCTYPE html>
<html>
<head><title>Admin Panel</title></head>
<body>
<h2>Admin Panel</h2>
<p>You authenticated as the real 'admin' database row. That's not
something anyone handed you -- see <a href="../catalog/search.php">catalog
search</a> for more of what this database will tell you if you ask it
the right way.</p>
<p><?= flag_for($secret, 5) ?></p>
</body>
</html>
PHP_EOF

sudo tee /var/www/html/staff/index.php >/dev/null <<'PHP_EOF'
<?php header('Location: login.php'); ?>
PHP_EOF

sudo tee /var/www/html/catalog/search.php >/dev/null <<'PHP_EOF'
<?php
$db = new PDO('sqlite:/var/www/html/data/library.db');
$q = $_GET['q'] ?? '';
$rows = [];
$error = '';
if ($q !== '') {
    $query = "SELECT title, author FROM books WHERE title LIKE '%$q%'";
    try {
        $stmt = $db->query($query);
        $rows = $stmt ? $stmt->fetchAll(PDO::FETCH_ASSOC) : [];
    } catch (Exception $e) {
        $error = 'Query failed: ' . $e->getMessage();
    }
}
?>
<!DOCTYPE html>
<html>
<head><title>Catalog Search</title></head>
<body>
<h2>Catalog Search</h2>
<form method="get">
  <input type="text" name="q" value="<?= htmlspecialchars($q) ?>" placeholder="title contains...">
  <button type="submit">Search</button>
</form>
<?php if ($error): ?><p style="color:red"><?= htmlspecialchars($error) ?></p><?php endif; ?>
<ul>
<?php foreach ($rows as $r): ?>
  <li><?= htmlspecialchars($r['title']) ?> — <?= htmlspecialchars($r['author']) ?></li>
<?php endforeach; ?>
</ul>
</body>
</html>
PHP_EOF

sudo tee /var/www/html/catalog/upload.php >/dev/null <<'PHP_EOF'
<?php
$msg = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['cover'])) {
    $f = $_FILES['cover'];
    $name = basename($f['name']);
    $claimed_type = $f['type'] ?? '';
    if (strpos($claimed_type, 'image/') !== 0) {
        $msg = "Only image uploads are allowed (got: " . htmlspecialchars($claimed_type) . ")";
    } else {
        $dest = '/var/www/html/uploads/' . $name;
        move_uploaded_file($f['tmp_name'], $dest);
        $msg = "Uploaded. It'll show up in /uploads/" . htmlspecialchars($name) . " once a librarian reviews it.";
    }
}
?>
<!DOCTYPE html>
<html>
<head><title>Suggest a Cover Image</title></head>
<body>
<h2>Suggest a Cover Image</h2>
<p><?= htmlspecialchars($msg) ?></p>
<form method="post" enctype="multipart/form-data">
  <input type="file" name="cover">
  <button type="submit">Upload</button>
</form>
</body>
</html>
PHP_EOF

sudo tee /var/www/html/catalog/index.php >/dev/null <<'PHP_EOF'
<!DOCTYPE html>
<html>
<head><title>Catalog</title></head>
<body>
<h2>Catalog</h2>
<ul>
<li><a href="search.php">Search the catalog</a></li>
<li><a href="upload.php">Suggest a cover image</a></li>
</ul>
<h3>Cover images on file</h3>
<ul>
<li><a href="../images/quiet_archivist.jpg">quiet_archivist.jpg</a></li>
<li><a href="../images/ledgers_of_dust.jpg">ledgers_of_dust.jpg</a></li>
<li><a href="../images/ferrymans_toll.jpg">ferrymans_toll.jpg</a></li>
</ul>
</body>
</html>
PHP_EOF

echo "== Honeypots =="
sudo tee /var/www/html/backup/old_passwords.txt.bak >/dev/null <<'EOF'
rotated out two years ago, kept here by mistake -- these do not work on
anything, don't waste your time:
admin / admin123
root / toor
backup_svc / Backup2019!
EOF
sudo tee /var/www/html/backup/not_a_flag.txt >/dev/null <<'EOF'
If you were hoping this was one of the ten, it isn't. Keep looking. -- P.O.R.
EOF

sudo chown -R www-data:www-data /var/www/html
sudo find /var/www/html -type d -exec chmod 755 {} +
sudo find /var/www/html -type f -exec chmod 644 {} +
sudo chmod 775 /var/www/html/data /var/www/html/uploads

echo "== Setting CTF_SECRET for Apache/PHP (file lives only on this guest) =="
echo "SetEnv CTF_SECRET \"$RELEASE_SECRET\"" | sudo tee /etc/apache2/conf-available/ctf-secret.conf >/dev/null
sudo a2enconf ctf-secret
sudo a2enmod rewrite

echo "== Generating cover images + stego, then seeding the database (as www-data) =="
sudo -u www-data CTF_SECRET="$RELEASE_SECRET" php /opt/make_covers.php
sudo -u www-data CTF_SECRET="$RELEASE_SECRET" php /opt/db/seed.php

echo "== flag7: outside the webroot, readable only via the upload-RCE vulnerability =="
php -r "require '/opt/generate_flags.php'; echo flag_for('$RELEASE_SECRET', 7);" | sudo tee /opt/flag7.txt >/dev/null
sudo chmod 644 /opt/flag7.txt

echo "== mcurie account (flag9, credential reuse) =="
sudo id -u mcurie >/dev/null 2>&1 || sudo useradd -m -s /bin/bash mcurie
echo "mcurie:$MCURIE_PASSWORD" | sudo chpasswd
php -r "require '/opt/generate_flags.php'; echo flag_for('$RELEASE_SECRET', 9);" | sudo tee /home/mcurie/flag9.txt >/dev/null
sudo chown mcurie:mcurie /home/mcurie/flag9.txt
sudo chmod 600 /home/mcurie/flag9.txt

echo "== SUID find -> root (flag10) =="
REAL_FIND=$(readlink -f /usr/bin/find)
sudo chmod u+s "$REAL_FIND"
php -r "require '/opt/generate_flags.php'; echo flag_for('$RELEASE_SECRET', 10);" | sudo tee /root/flag10.txt >/dev/null
sudo chmod 600 /root/flag10.txt

echo "== Restarting services =="
sudo systemctl restart apache2
sudo systemctl enable apache2
sudo pkill -9 -f 'sshd: /usr/sbin/sshd -D \[listener\]' 2>/dev/null || true
sleep 1
sudo systemctl restart ssh
sudo systemctl enable ssh

echo "Done."
