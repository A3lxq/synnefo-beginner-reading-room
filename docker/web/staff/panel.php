<?php
session_start();
require_once '/opt/generate_flags.php';
$secret = getenv('CTF_SECRET');

// Server-side check against the session value set by login.php's own
// DB query result -- NOT the client-controlled "role" cookie. The only
// way $_SESSION['db_username'] becomes 'admin' is if login.php's raw
// SQL query actually returned the admin row, which (since no admin
// credential is disclosed anywhere) means a real SQL injection
// authentication bypass happened.
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
