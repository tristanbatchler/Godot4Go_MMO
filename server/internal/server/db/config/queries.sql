-- name: GetUserByUsername :one
SELECT * FROM users
WHERE username = ? LIMIT 1;

-- name: CreateUser :one
INSERT INTO users (
    username, password_hash
) VALUES (
    ?, ?
)
RETURNING *;

-- name: CreatePlayer :one
INSERT INTO players (
    user_id, name, color
) VALUES (
    ?, ?, ?
)
RETURNING *;

-- name: GetPlayerByUserId :one
SELECT * FROM players
WHERE user_id = ? LIMIT 1;

-- name: UpdatePlayerBestScore :exec
UPDATE players
SET best_score = ?
WHERE id = ?;

-- name: GetTopScores :many
SELECT name, best_score
FROM players
ORDER BY best_score DESC
LIMIT ?
OFFSET ?;

-- name: GetPlayerByName :one
SELECT * FROM players
WHERE name LIKE ?
LIMIT 1;

-- name: GetPlayerRank :one
SELECT COUNT(*) + 1 as "rank" FROM players
WHERE best_score >= (
    SELECT best_score FROM players p2
    WHERE p2.id = ?
);