#!/bin/bash
set -euo pipefail

: "${CTF_SECRET:?CTF_SECRET must be set (see start.sh / .env)}"

MCURIE_PASSWORD="librarian123"  # same creds disclosed as the web app's default login -- credential reuse, by design

mkdir -p /var/www/html/data /var/www/html/backup /var/www/html/uploads /var/www/html/images
php /opt/make_covers.php
php /opt/db/seed.php

# flag7: dropped outside the webroot, readable only via actual RCE
# through the upload vulnerability (not a direct URL guess).
php -r "require '/opt/generate_flags.php'; echo flag_for(getenv('CTF_SECRET'), 7);" > /opt/flag7.txt
chmod 644 /opt/flag7.txt

# mcurie: the Linux account for the librarian, reachable only by
# reusing the web app's default credentials (flag9 in her home dir).
id -u mcurie >/dev/null 2>&1 || useradd -m -s /bin/bash mcurie
echo "mcurie:$MCURIE_PASSWORD" | chpasswd
php -r "require '/opt/generate_flags.php'; echo flag_for(getenv('CTF_SECRET'), 9);" > /home/mcurie/flag9.txt
chown mcurie:mcurie /home/mcurie/flag9.txt
chmod 600 /home/mcurie/flag9.txt

# Stage 10: SUID misconfig on `find` (classic GTFOBins privesc).
chmod u+s /usr/bin/find

php -r "require '/opt/generate_flags.php'; echo flag_for(getenv('CTF_SECRET'), 10);" > /root/flag10.txt
chmod 600 /root/flag10.txt

chown -R www-data:www-data /var/www/html/data /var/www/html/uploads
chmod 755 /var/www/html/uploads   # intentionally writable+executable-PHP, the vulnerability itself

echo "[entrypoint] Reading Room ready."
exec apache2-foreground
