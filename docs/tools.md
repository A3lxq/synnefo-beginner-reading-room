# Tools you'll use in this box

| Tool | What it's for here |
|---|---|
| `nmap` | Confirm only port 80 is open. |
| Browser / curl | View source, read comments. |
| Browser dev tools or Burp Suite | Inspect and edit cookies (flag 3), craft a multipart upload with a custom `Content-Type` (flag 7). |
| `gobuster` / `ffuf` | Brute-force hidden paths like `/backup/`. |
| Manual SQL injection | `' OR '1'='1' -- ` style payloads (flag 5), `UNION SELECT` column-count discovery (flag 6). |
| `sqlmap` | Automate the UNION extraction in flag 6 once you've found the injectable parameter. |
| `curl -F` | Upload a file with a forced filename/Content-Type without a browser. |
| `steghide` | Extract hidden data from a JPEG, given the right passphrase (flag 8). |
| `su` | Switch to another Linux account once you have its (reused) password (flag 9). |
| GTFOBins (gtfobins.github.io) | Look up how a SUID binary like `find` turns into a root shell (flag 10). |
