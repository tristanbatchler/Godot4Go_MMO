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
    user_id, name
) VALUES (
    ?, ?
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