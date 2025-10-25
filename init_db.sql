-- Отключаем вывод
\set QUIET on

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

WITH new_users(name) AS (
    VALUES
    ('Ivan'),
    ('Maria'),
    ('Alex')
)
INSERT INTO users (name)
SELECT name FROM new_users
WHERE NOT EXISTS (SELECT 1 FROM users WHERE users.name = new_users.name);
