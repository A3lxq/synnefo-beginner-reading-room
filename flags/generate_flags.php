<?php
// Deterministic per-deployment flag generator (PHP side, used inside the
// running container). Same HMAC-SHA256(secret, "<box_id>:<n>") scheme as
// every other box in this series, so organizer/verify.py (Python) can
// recompute the identical value -- HMAC-SHA256 is the same across both.
define('BOX_ID', 'beginner-reading-room');

function flag_for(string $secret, int $n): string {
    $digest = hash_hmac('sha256', BOX_ID . ':' . $n, $secret);
    return 'HLC{' . substr($digest, 0, 10) . '}';
}

if (php_sapi_name() === 'cli' && isset($argv[0]) && realpath($argv[0]) === __FILE__) {
    $secret = getenv('CTF_SECRET');
    if (!$secret) {
        fwrite(STDERR, "CTF_SECRET not set\n");
        exit(1);
    }
    if ($argc < 2) {
        fwrite(STDERR, "usage: generate_flags.php <n>\n");
        exit(1);
    }
    echo flag_for($secret, (int)$argv[1]), "\n";
}
