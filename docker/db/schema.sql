CREATE TABLE books (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    cover_image TEXT NOT NULL
);

CREATE TABLE staff (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    password TEXT NOT NULL
);

-- Found only via UNION-based SQLi against catalog/search.php, which
-- selects exactly two columns (title, author) -- so a working UNION
-- needs exactly two columns here too: note (flag6) and passphrase (the
-- steghide password for flag8's cover image).
CREATE TABLE staff_notes (
    id INTEGER PRIMARY KEY,
    note TEXT NOT NULL,
    passphrase TEXT NOT NULL
);
