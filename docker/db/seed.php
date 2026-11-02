<?php
// Runs once per container start (entrypoint.sh), before Apache starts.
// Builds a fresh SQLite DB from schema.sql and seeds it with flags.
require_once '/opt/generate_flags.php';

$secret = getenv('CTF_SECRET');
if (!$secret) { fwrite(STDERR, "CTF_SECRET not set\n"); exit(1); }

$dbPath = '/var/www/html/data/library.db';
if (file_exists($dbPath)) unlink($dbPath);

$pdo = new PDO('sqlite:' . $dbPath);
$pdo->exec(file_get_contents('/opt/schema.sql'));

$flag4 = flag_for($secret, 4);
$flag6 = flag_for($secret, 6);
$flag8 = flag_for($secret, 8);  // hidden in the cover image via steghide, not the DB

$stego_passphrase = 'InkAndIvy22';

$pdo->exec("INSERT INTO books (title, author, cover_image) VALUES
    ('The Quiet Archivist', 'R. Okafor', 'quiet_archivist.jpg'),
    ('Ledgers of Dust', 'M. Curie-Hall', 'ledgers_of_dust.jpg'),
    ('The Ferryman''s Toll', 'Unknown', 'ferrymans_toll.jpg')");

// id=1 (admin) must sort/return first for a classic `' OR '1'='1' --`
// auth-bypass payload with no ORDER BY -- that's the entire point: no
// admin credential is ever disclosed anywhere, injection is the only way in.
$admin_pw = bin2hex(random_bytes(16));  // unknown to anyone, including the DB owner's own notes
$pdo->exec("INSERT INTO staff (id, username, password) VALUES (1, 'admin', " . $pdo->quote($admin_pw) . ")");
$pdo->exec("INSERT INTO staff (id, username, password) VALUES (2, 'librarian', 'librarian123')");

$stmt = $pdo->prepare("INSERT INTO staff_notes (note, passphrase) VALUES (?, ?)");
$stmt->execute([$flag6, $stego_passphrase]);

// Also drop a copy of flag4 into a leftover "backup" file (exposed via
// directory brute-forcing, not injection) and write the stego passphrase
// + flag8 into the actual image via steghide.
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
