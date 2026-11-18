-- One table, for the tests of this suite that need no more.
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT,
    age INTEGER NOT NULL DEFAULT 0
) STRICT;

-- A parameter in SET and in WHERE.
UPDATE users SET name = ? WHERE id = ?;
