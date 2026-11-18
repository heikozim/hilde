/* Notes belong to a user; a note's body is bytes. */
CREATE TABLE notes (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    body BLOB NOT NULL
) STRICT;

ALTER TABLE users ADD COLUMN city TEXT;

INSERT INTO users (name, age) VALUES ('root', 99);
