<?php
// "Suggest a cover image" feature. INTENTIONALLY VULNERABLE: validates
// the CLIENT-SUPPLIED Content-Type of the uploaded part (trivially
// spoofable in any HTTP client/Burp) instead of the file's real
// content or a server-side extension allowlist. A file named
// "shell.php" with its multipart Content-Type set to "image/jpeg"
// sails straight through and keeps its real, executable .php name --
// classic unrestricted-upload-to-RCE via a client-trusted MIME check.
$msg = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['cover'])) {
    $f = $_FILES['cover'];
    $name = basename($f['name']);
    $claimed_type = $f['type'] ?? '';  // client-controlled, not validated server-side
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
