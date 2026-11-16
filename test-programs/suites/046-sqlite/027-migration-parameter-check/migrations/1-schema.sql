-- A parameter in a CHECK of a table.
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT,
    age INTEGER NOT NULL DEFAULT 0 CHECK (age >= ?)
) STRICT;
