package objects

type Player struct {
	Name      string
	X         float64
	Y         float64
	Radius    float64
	Direction float64
	Speed     float64
	BestScore int64
	DbId      int64
}

type Spore struct {
	X      float64
	Y      float64
	Radius float64
}
