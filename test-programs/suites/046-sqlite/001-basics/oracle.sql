-- The oracle for this test: the same statements as Test.hiq, with the
-- values written in, run by the sqlite3 command-line shell after the
-- migrations (scripts/sqlite/oracle.sh).  Each SELECT prints its line in
-- the format Test.hiq prints it, so that the two outputs can be compared
-- line by line.
SELECT 'migrations applied: 2';
INSERT INTO users (name, email, age, score) VALUES ('alice', 'alice@example.org', 34, 1.5);
SELECT 'insert alice: ' || changes() || ' row(s)';
INSERT INTO users (name, email, age, score) VALUES ('bob', NULL, 27, NULL);
SELECT 'insert bob: ' || changes() || ' row(s)';
INSERT INTO users (name, age) VALUES ('carol', 41);
SELECT 'insert carol: ' || changes() || ' row(s)';
SELECT id || ' ' || name || ' ' || coalesce(email, 'NULL') || ' ' || age || ' '
       || CASE WHEN score IS NULL THEN 'NULL' ELSE printf('%f', score) END
  FROM users ORDER BY id;
SELECT 'people ' || count(*) || ', oldest ' || coalesce(max(age), 'NULL')
       || ', average score ' || coalesce(printf('%f', avg(score)), 'NULL')
  FROM users;
INSERT INTO notes (user_id, body) VALUES (3, CAST('bytes of a note' AS BLOB));
SELECT 'insert note: ' || changes() || ' row(s)';
SELECT u.name || ': ' || coalesce(CAST(n.body AS TEXT), 'NULL')
  FROM users u LEFT JOIN notes n ON n.user_id = u.id ORDER BY u.id;
UPDATE users SET city = 'Bern' WHERE age > 30 AND name <> 'root';
SELECT 'update: ' || changes() || ' row(s)';
SELECT 'removed ' || id FROM (SELECT id FROM users WHERE name = 'carol');
DELETE FROM users WHERE name = 'carol';
SELECT name || ' in ' || coalesce(city, 'NULL')
  FROM users WHERE age BETWEEN 20 AND 50 ORDER BY name;
INSERT INTO users (name) VALUES ('alice');
