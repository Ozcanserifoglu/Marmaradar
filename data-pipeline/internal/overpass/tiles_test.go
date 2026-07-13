package overpass

import "testing"

func TestTurkeyTileGrid(t *testing.T) {
	tiles := TurkeyTileGrid()
	if len(tiles) == 0 {
		t.Fatal("expected tiles")
	}
	for _, tile := range tiles {
		if tile[0] >= tile[2] || tile[1] >= tile[3] {
			t.Fatalf("invalid tile bounds: %v", tile)
		}
	}
}

func TestTileQuery(t *testing.T) {
	q := TileQuery(35.8, 25.66, 36.8, 26.66)
	if q == "" {
		t.Fatal("empty query")
	}
}
