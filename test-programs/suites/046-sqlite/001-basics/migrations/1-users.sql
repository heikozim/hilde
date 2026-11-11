-- The people of the test.
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT,
    age INTEGER NOT NULL DEFAULT 0,
    score REAL
) STRICT;

CREATE UNIQUE INDEX users_name ON users (name);
