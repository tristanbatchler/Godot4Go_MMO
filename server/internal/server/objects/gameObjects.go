package objects

import "time"

type Player struct {
	Name      string
	X         float64
	Y         float64
	Radius    float64
	Direction float64
	Speed     float64
	BestScore int64
	DbId      int64
	Color     int32
}

type Spore struct {
	X         float64
	Y         float64
	Radius    float64
	DroppedBy *Player
	DroppedAt time.Time
}
