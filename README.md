# Case File 2 (Beginner) — Reading Room

Part of **The Halcyon Protocol** CTF series. This box stands alone — you do
not need any other box in the series to play it.

> See [`STORY.md`](STORY.md) for the full case file.

## What this is

A single deliberately-vulnerable web application (PHP + Apache + SQLite)
aimed at players who've done one or two boxes before. 10 flags, no decoys.
The first three are easy; difficulty then climbs through directory
brute-forcing, SQL injection, file upload RCE, steganography, credential
reuse, and a SUID privilege escalation.

**This machine is intentionally vulnerable. Run it only on an isolated
network.**

## Requirements

- Docker + Docker Compose
- A player machine with: `nmap`, `curl`, a browser (+ dev tools or Burp
  Suite Community), `gobuster` or `ffuf`, `sqlmap` (optional — the UNION
  injection is manually solvable too), `steghide`, a way to send a
  multipart upload with a custom `Content-Type` (Burp, or `curl -F`)

## Starting the box

```
./start.sh
```
Generates a fresh `.env` with a random per-deployment secret and brings the
stack up.

- Web: http://localhost:8002

## Flag format

`HLC{xxxxxxxxxx}` — submit exactly as found.

## Rules

- No decoy flags: everything matching the flag format is real and counts.
- Some things in this box are honeypots — red herrings that cost you time,
  not flags.
- Don't attack this box over a shared or public network.

## More

- [`STORY.md`](STORY.md) — the in-universe case file
- [`docs/hints.md`](docs/hints.md) — progressive hints
- [`docs/tools.md`](docs/tools.md) — what each tool is for
- [`docs/writeup/WRITEUP.md`](docs/writeup/WRITEUP.md) — full spoiler walkthrough
