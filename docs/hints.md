# Hints (progressive — try to only read as far as you need)

**Flag 1** — View page source on `/`.

**Flag 2** — This library isn't subtle about its default credentials.
Think of the most generic staff-login guess you'd try first.

**Flag 3** — After logging in, look at what cookie your browser is holding
onto, and ask whether the dashboard really double-checks it.

**Flag 4** — Brute-force common directory names at the web root. "backup"
is not an unusual one to try.

**Flag 5** — The same login form that took your default creds builds its
SQL query by just pasting your input in. What happens if your "username"
is itself a SQL condition that's always true?

**Flag 6** — The catalog search box is vulnerable too, but differently —
try adding a single quote and see what breaks, then work out how many
columns the original query selects before you try a UNION.

**Flag 7** — The upload feature's filter isn't checking your file's real
content or its extension — it's checking something your client sends that
you also control.

**Flag 8** — One of the three cover images has something extra in it.
You'll need a password you didn't start with — look at what else you
pulled out of the database in flag 6.

**Flag 9** — Once you have command execution, look at `/etc/passwd` for
real Linux accounts. One of them shares a password you already know.

**Flag 10** — Check for SUID binaries (`find / -perm -4000 -type f
2>/dev/null`). If one of the common Unix utilities shows up, GTFOBins
almost certainly has a privilege-escalation technique for it.
