<?php
session_start();
require_once '/opt/generate_flags.php';
$secret = getenv('CTF_SECRET');

if (!isset($_SESSION['db_username'])) {
    header('Location: login.php');
    exit;
}

// INTENTIONALLY VULNERABLE: trusts the client-supplied "role" cookie
// directly, with no server-side check against the authenticated
// session. Any staff member can edit role=staff -> role=admin in their
// browser's dev tools and get the admin view here (flag3). This is
// deliberately a WEAKER check than panel.php (which re-verifies against
// the DB-authenticated session) -- two different lessons, two flags.
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
