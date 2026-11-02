# Organizer manifest — Reading Room (Beginner)

Keep this file (and this whole `organizer/` directory) off any
player-facing host. Flag *values* are never written here — re-derive them
from the deployment's `CTF_SECRET` (HMAC-SHA256("beginner-reading-room:N",
secret), first 10 hex chars, wrapped `HLC{...}`).

| # | Difficulty | Concept taught | Primary tool(s) | Where it lives |
|---|---|---|---|---|
| 1 | Easy | Reading page source | Browser view-source / curl | HTML comment on `/` |
| 2 | Easy | Default/weak credentials | Browser, curl | `librarian` / `librarian123` on `/staff/login.php` |
| 3 | Easy | Client-trusted cookie (broken access control) | Browser dev tools / Burp / curl -H | Edit `role=staff` -> `role=admin` cookie on `/staff/dashboard.php` |
| 4 | Medium | Directory/file brute-forcing, exposed backups | `gobuster`/`ffuf`, curl | `/backup/catalog_backup.sql.txt` |
| 5 | Medium | SQL injection authentication bypass | Manual payload (`' OR '1'='1' --`) | `/staff/login.php` -> `/staff/panel.php` (session re-verified server-side, not cookie-trusted) |
| 6 | Medium/Hard | UNION-based SQL injection, blind column-count discovery | Manual UNION, `sqlmap` | `/catalog/search.php?q=...UNION SELECT note,passphrase FROM staff_notes` |
| 7 | Hard | Unrestricted file upload (client Content-Type trusted, not real content/extension policy) -> RCE | Burp/curl multipart override, a one-line PHP webshell | `/catalog/upload.php` -> `/uploads/<name>.php` |
| 8 | Hard | Steganography | `steghide` (passphrase recovered from flag 6's UNION row) | `/images/ledgers_of_dust.jpg` |
| 9 | Hard | Credential reuse pivot (web creds reused as a Linux account) | `su` (via the RCE shell) | `/home/mcurie/flag9.txt` |
| 10 | Hardest | SUID misconfiguration -> privilege escalation | GTFOBins `find` entry | `/root/flag10.txt` |

## Honeypots (never flag-shaped, cost time only)
- `/backup/old_passwords.txt.bak` — plausible-looking but explicitly inert creds.
- `/backup/not_a_flag.txt` — explicitly says it isn't one of the ten.
- `images/quiet_archivist.jpg`, `images/ferrymans_toll.jpg` — real cover
  images with nothing hidden in them (only `ledgers_of_dust.jpg` carries flag8).

## Fixed design constants (intentional, not secret-derived)
- Default creds: `librarian` / `librarian123`.
- Admin DB row (`id=1`) has a random, genuinely-unknown password — reachable
  only via the SQLi auth-bypass path, never disclosed anywhere.
- Stego passphrase: `InkAndIvy22` (only discoverable via the flag 6 UNION row).
- `mcurie`'s Linux password == the web app's default creds (`librarian123`).
- Privesc: `chmod u+s /usr/bin/find` (classic GTFOBins pattern).
- Upload bypass: app trusts the client-supplied multipart `Content-Type`
  instead of validating real file content or using an extension allowlist;
  Apache in this image executes exactly `*.php` (see `docker/Dockerfile`'s
  base image, `docker-php.conf`).
