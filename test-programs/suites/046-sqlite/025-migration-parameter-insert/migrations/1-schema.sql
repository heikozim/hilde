-- One table, for the tests of this suite that need no more.
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT,
    age INTEGER NOT NULL DEFAULT 0
) STRICT;

-- A parameter where a value goes: a migration is run as it stands, so
-- there is nothing it could stand for.
INSERT INTO users (name) VALUES (?);
