package overpass

import (
	"fmt"
	"math"
	"strings"

	"github.com/radar-alert/data-pipeline/internal/normalize"
)

// TurkeyTileGrid returns 1°×1° bounding boxes covering Turkey as
// (south, west, north, east) tuples for Overpass queries.
func TurkeyTileGrid() [][4]float64 {
	const (
		south = 35.8
		west  = 25.66
		north = 42.1
		east  = 44.8
		step  = 1.0
	)

	var tiles [][4]float64
	for lat := south; lat < north; lat += step {
		for lon := west; lon < east; lon += step {
			tileNorth := lat + step
			tileEast := lon + step
			if tileNorth > north {
				tileNorth = north
			}
			if tileEast > east {
				tileEast = east
			}
			tiles = append(tiles, [4]float64{lat, lon, tileNorth, tileEast})
		}
	}
	return tiles
}

func TileQuery(south, west, north, east float64) string {
	return fmt.Sprintf(`[out:json][timeout:90];
(
  node["highway"="speed_camera"](%f,%f,%f,%f);
  relation["type"="enforcement"]["enforcement"~"maxspeed|average_speed"](%f,%f,%f,%f);
);
out body;
>;
out skel qt;`, south, west, north, east, south, west, north, east)
}

func RelationsToCorridors(relations []overpassElement, nodes map[int64]overpassElement) []normalize.CorridorRecord {
	var corridors []normalize.CorridorRecord

	for _, rel := range relations {
		if rel.Tags["type"] != "enforcement" {
			continue
		}
		enf := rel.Tags["enforcement"]
		if enf != "average_speed" && enf != "maxspeed" {
			continue
		}

		entry, exit, ok := relationGateCoords(rel, nodes)
		if !ok {
			continue
		}

		name := firstTag(rel.Tags, "name", "ref")
		if name == "" {
			name = fmt.Sprintf("osm:relation:%d", rel.ID)
		}

		speed := int16(50)
		if ms := normalize.ParseMaxspeed(rel.Tags); ms != nil {
			speed = *ms
		}

		midLat := (entry.lat + exit.lat) / 2
		midLon := (entry.lon + exit.lon) / 2

		corridors = append(corridors, normalize.CorridorRecord{
			ExternalID:  fmt.Sprintf("osm:relation:%d", rel.ID),
			Name:        name,
			RegionCode:  normalize.RegionForPoint(midLat, midLon),
			MaxspeedKmh: speed,
			LengthM:     haversineM(entry.lat, entry.lon, exit.lat, exit.lon),
			Direction:   "both",
			Gates: []normalize.CorridorGate{
				{GateType: "entry", Lat: entry.lat, Lon: entry.lon, RadiusM: 100, Sequence: 0},
				{GateType: "exit", Lat: exit.lat, Lon: exit.lon, RadiusM: 100, Sequence: 0},
			},
			SourceTags: rel.Tags,
		})
	}
	return corridors
}

type latLon struct {
	lat, lon float64
}

func relationGateCoords(rel overpassElement, nodes map[int64]overpassElement) (entry, exit latLon, ok bool) {
	var entryIDs, exitIDs []int64
	var deviceNodes []int64

	for _, m := range rel.Members {
		if m.Type != "node" {
			continue
		}
		role := strings.ToLower(m.Role)
		switch role {
		case "from", "entry", "start":
			entryIDs = append(entryIDs, m.Ref)
		case "to", "exit", "end":
			exitIDs = append(exitIDs, m.Ref)
		default:
			deviceNodes = append(deviceNodes, m.Ref)
		}
	}

	if len(entryIDs) > 0 && len(exitIDs) > 0 {
		e, okE := nodeLatLon(nodes, entryIDs[0])
		x, okX := nodeLatLon(nodes, exitIDs[len(exitIDs)-1])
		return e, x, okE && okX
	}
	if len(deviceNodes) >= 2 {
		e, okE := nodeLatLon(nodes, deviceNodes[0])
		x, okX := nodeLatLon(nodes, deviceNodes[len(deviceNodes)-1])
		return e, x, okE && okX
	}
	return entry, exit, false
}

func nodeLatLon(nodes map[int64]overpassElement, id int64) (latLon, bool) {
	n, ok := nodes[id]
	if !ok {
		return latLon{}, false
	}
	return latLon{lat: n.Lat, lon: n.Lon}, true
}

func firstTag(tags map[string]string, keys ...string) string {
	for _, k := range keys {
		if v := tags[k]; v != "" {
			return v
		}
	}
	return ""
}

func haversineM(lat1, lon1, lat2, lon2 float64) float64 {
	const earthR = 6371000
	const deg = math.Pi / 180
	φ1 := lat1 * deg
	φ2 := lat2 * deg
	dφ := (lat2 - lat1) * deg
	dλ := (lon2 - lon1) * deg
	a := math.Sin(dφ/2)*math.Sin(dφ/2) +
		math.Cos(φ1)*math.Cos(φ2)*math.Sin(dλ/2)*math.Sin(dλ/2)
	return 2 * earthR * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
}
