package objects

import "math/rand/v2"

func SpawnCoords() (float64, float64) {
	bound := 3000.0
	return rand.Float64() * bound, rand.Float64() * bound
}
