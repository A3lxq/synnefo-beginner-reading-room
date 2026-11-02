<?php
$db = new PDO('sqlite:/var/www/html/data/library.db');
$q = $_GET['q'] ?? '';
$rows = [];
$error = '';

if ($q !== '') {
    // INTENTIONALLY VULNERABLE: raw string-built query, exactly 2
    // selected columns (title, author) -- a UNION-based injection here
    // needs exactly 2 columns too. No prepared statement on purpose.
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
