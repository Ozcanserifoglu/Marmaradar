package normalize

// Turkey approximate bounds (west, south, east, north).
const (
	TurkeyWest  = 25.66
	TurkeySouth = 35.8
	TurkeyEast  = 44.8
	TurkeyNorth = 42.1
)

type regionBox struct {
	code                string
	west, south, east, north float64
}

// Regions are checked in order; first match wins.
var regionBoxes = []regionBox{
	{code: "bursa", west: 28.75, south: 39.95, east: 29.55, north: 40.55},
	{code: "istanbul", west: 28.4, south: 40.8, east: 29.5, north: 41.35},
	{code: "ankara", west: 32.3, south: 39.6, east: 33.2, north: 40.2},
	{code: "izmir", west: 26.8, south: 38.1, east: 27.5, north: 38.7},
	{code: "marmara", west: 27.5, south: 40.0, east: 30.5, north: 41.5},
}

func RegionForPoint(lat, lon float64) string {
	for _, r := range regionBoxes {
		if lat >= r.south && lat <= r.north && lon >= r.west && lon <= r.east {
			return r.code
		}
	}
	if lat >= TurkeySouth && lat <= TurkeyNorth && lon >= TurkeyWest && lon <= TurkeyEast {
		return "turkey"
	}
	return "turkey"
}

func TurkeyBbox() string {
	return "25.66,35.8,44.8,42.1"
}
