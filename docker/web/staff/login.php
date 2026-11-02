<?php
session_start();
require_once '/opt/generate_flags.php';
$secret = getenv('CTF_SECRET');
$db = new PDO('sqlite:/var/www/html/data/library.db');
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $u = $_POST['username'] ?? '';
    $p = $_POST['password'] ?? '';

    // INTENTIONALLY VULNERABLE: raw string-built query, no parameter
    // binding. Two separate flaws live here on purpose:
    //  1. 'librarian' / 'librarian123' are real, working default creds
    //     (flag2 -- no injection needed, just weak/guessable creds).
    //  2. The query itself is injectable, and there is NO legitimate
    //     admin credential anywhere a player can find -- the only way
    //     to authenticate as 'admin' (id=1, checked server-side by
    //     panel.php, not just a client-trusted cookie) is a real SQL
    //     injection auth bypass (flag5).
    $query = "SELECT * FROM staff WHERE username = '$u' AND password = '$p' LIMIT 1";
    $row = null;
    try {
        $stmt = $db->query($query);
        $row = $stmt ? $stmt->fetch(PDO::FETCH_ASSOC) : null;
    } catch (Exception $e) {
        $error = "Database error.";
    }

    if ($row) {
        $_SESSION['db_username'] = $row['username'];   // server-side, tamper-resistant
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
