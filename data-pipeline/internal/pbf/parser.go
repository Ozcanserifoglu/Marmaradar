package pbf

import (
	"fmt"
	"io"
	"math"
	"os"
	"strings"

	"github.com/qedus/osmpbf"
	"github.com/radar-alert/data-pipeline/internal/normalize"
)

type ParseResult struct {
	Cameras   []normalize.CameraRecord
	Corridors []normalize.CorridorRecord
}

type coord struct {
	lat, lon float64
}

type wayData struct {
	tags    map[string]string
	nodeIDs []int64
}

type relationData struct {
	tags    map[string]string
	members []osmpbf.Member
}

type scanResult struct {
	cameras              []normalize.CameraRecord
	enforcementWays      map[int64]wayData
	enforcementRelations map[int64]relationData
	relationWayRefs      map[int64]struct{}
	neededNodes          map[int64]struct{}
}

// ParseFile reads a Geofabrik OSM PBF extract and extracts speed cameras and
// average-speed enforcement corridors.
func ParseFile(path string) (*ParseResult, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	scanned, err := scanPass(f)
	if err != nil {
		return nil, fmt.Errorf("scan pass: %w", err)
	}

	if _, err := f.Seek(0, io.SeekStart); err != nil {
		return nil, fmt.Errorf("rewind pbf: %w", err)
	}

	relationWays, err := waysPass(f, scanned.relationWayRefs, scanned.enforcementWays)
	if err != nil {
		return nil, fmt.Errorf("ways pass: %w", err)
	}

	for _, w := range relationWays {
		for _, nodeID := range w.nodeIDs {
			scanned.neededNodes[nodeID] = struct{}{}
		}
	}

	if _, err := f.Seek(0, io.SeekStart); err != nil {
		return nil, fmt.Errorf("rewind pbf: %w", err)
	}

	nodeCoords, err := coordsPass(f, scanned.neededNodes)
	if err != nil {
		return nil, fmt.Errorf("coords pass: %w", err)
	}

	allWays := make(map[int64]wayData, len(scanned.enforcementWays)+len(relationWays))
	for id, w := range scanned.enforcementWays {
		allWays[id] = w
	}
	for id, w := range relationWays {
		allWays[id] = w
	}

	corridors := buildCorridors(scanned.enforcementWays, scanned.enforcementRelations, allWays, nodeCoords)

	return &ParseResult{
		Cameras:   scanned.cameras,
		Corridors: corridors,
	}, nil
}

func scanPass(r io.Reader) (*scanResult, error) {
	result := &scanResult{
		enforcementWays:      make(map[int64]wayData),
		enforcementRelations: make(map[int64]relationData),
		relationWayRefs:      make(map[int64]struct{}),
		neededNodes:          make(map[int64]struct{}),
	}

	decoder := osmpbf.NewDecoder(r)
	if err := decoder.Start(4); err != nil {
		return nil, err
	}

	for {
		v, decErr := decoder.Decode()
		if decErr == io.EOF {
			break
		}
		if decErr != nil {
			return nil, decErr
		}

		switch entity := v.(type) {
		case *osmpbf.Node:
			if entity.Tags["highway"] == "speed_camera" {
				result.cameras = append(result.cameras, nodeToCamera(entity))
			}
		case *osmpbf.Way:
			if isAverageSpeedWay(entity.Tags) {
				result.enforcementWays[entity.ID] = wayData{
					tags:    entity.Tags,
					nodeIDs: append([]int64(nil), entity.NodeIDs...),
				}
				for _, id := range entity.NodeIDs {
					result.neededNodes[id] = struct{}{}
				}
			}
		case *osmpbf.Relation:
			if !isEnforcementRelation(entity.Tags) {
				continue
			}
			result.enforcementRelations[entity.ID] = relationData{
				tags:    entity.Tags,
				members: append([]osmpbf.Member(nil), entity.Members...),
			}
			for _, m := range entity.Members {
				if m.Type == osmpbf.NodeType {
					result.neededNodes[m.ID] = struct{}{}
				}
				if m.Type == osmpbf.WayType {
					result.relationWayRefs[m.ID] = struct{}{}
				}
			}
		}
	}

	return result, nil
}

func waysPass(r io.Reader, refs map[int64]struct{}, existing map[int64]wayData) (map[int64]wayData, error) {
	out := make(map[int64]wayData)
	if len(refs) == 0 {
		return out, nil
	}

	decoder := osmpbf.NewDecoder(r)
	if err := decoder.Start(4); err != nil {
		return nil, err
	}

	for {
		v, err := decoder.Decode()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, err
		}
		way, ok := v.(*osmpbf.Way)
		if !ok {
			continue
		}
		if _, already := existing[way.ID]; already {
			continue
		}
		if _, want := refs[way.ID]; !want {
			continue
		}
		out[way.ID] = wayData{tags: way.Tags, nodeIDs: append([]int64(nil), way.NodeIDs...)}
	}
	return out, nil
}

func coordsPass(r io.Reader, needed map[int64]struct{}) (map[int64]coord, error) {
	if len(needed) == 0 {
		return map[int64]coord{}, nil
	}

	nodeCoords := make(map[int64]coord, len(needed))
	decoder := osmpbf.NewDecoder(r)
	if err := decoder.Start(4); err != nil {
		return nil, err
	}

	for {
		v, err := decoder.Decode()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, err
		}
		node, ok := v.(*osmpbf.Node)
		if !ok {
			continue
		}
		if _, want := needed[node.ID]; want {
			nodeCoords[node.ID] = coord{lat: node.Lat, lon: node.Lon}
		}
	}
	return nodeCoords, nil
}

func nodeToCamera(n *osmpbf.Node) normalize.CameraRecord {
	return normalize.CameraRecord{
		ExternalID:  fmt.Sprintf("osm:node:%d", n.ID),
		RegionCode:  normalize.RegionForPoint(n.Lat, n.Lon),
		Lat:         n.Lat,
		Lon:         n.Lon,
		RoadName:    firstNonEmpty(n.Tags["ref"], n.Tags["name"]),
		MaxspeedKmh: normalize.ParseMaxspeed(n.Tags),
		CameraType:  normalize.CameraTypeFromTags(n.Tags),
		Active:      true,
		SourceTags:  n.Tags,
		Confidence:  0.75,
	}
}

func isAverageSpeedWay(tags map[string]string) bool {
	return enforcementKind(tags) == "average_speed"
}

func isEnforcementRelation(tags map[string]string) bool {
	if tags["type"] != "enforcement" {
		return false
	}
	kind := enforcementKind(tags)
	return kind == "average_speed" || kind == "maxspeed"
}

func enforcementKind(tags map[string]string) string {
	if v := tags["enforcement"]; v != "" {
		return v
	}
	if v := tags["enforcement:highway"]; v != "" {
		return v
	}
	return ""
}

func buildCorridors(
	enforcementWays map[int64]wayData,
	relations map[int64]relationData,
	allWays map[int64]wayData,
	nodes map[int64]coord,
) []normalize.CorridorRecord {
	var corridors []normalize.CorridorRecord
	seen := make(map[string]struct{})

	for id, w := range enforcementWays {
		entry, exit, ok := wayEndpoints(w.nodeIDs, nodes)
		if !ok {
			continue
		}
		extID := fmt.Sprintf("osm:way:%d", id)
		if _, dup := seen[extID]; dup {
			continue
		}
		seen[extID] = struct{}{}
		corridors = append(corridors, wayToCorridor(extID, w.tags, entry, exit))
	}

	for id, rel := range relations {
		entry, exit, ok := relationEndpoints(rel, allWays, nodes)
		if !ok {
			continue
		}
		extID := fmt.Sprintf("osm:relation:%d", id)
		if _, dup := seen[extID]; dup {
			continue
		}
		seen[extID] = struct{}{}
		corridors = append(corridors, wayToCorridor(extID, rel.tags, entry, exit))
	}

	return corridors
}

func wayEndpoints(nodeIDs []int64, nodes map[int64]coord) (entry, exit coord, ok bool) {
	if len(nodeIDs) < 2 {
		return entry, exit, false
	}
	start, hasStart := nodes[nodeIDs[0]]
	end, hasEnd := nodes[nodeIDs[len(nodeIDs)-1]]
	if !hasStart || !hasEnd {
		return entry, exit, false
	}
	return start, end, true
}

func relationEndpoints(rel relationData, ways map[int64]wayData, nodes map[int64]coord) (entry, exit coord, ok bool) {
	var entryNodes, exitNodes []int64
	var deviceNodes []int64
	var wayIDs []int64

	for _, m := range rel.members {
		role := strings.ToLower(m.Role)
		switch m.Type {
		case osmpbf.NodeType:
			switch role {
			case "from", "entry", "start":
				entryNodes = append(entryNodes, m.ID)
			case "to", "exit", "end":
				exitNodes = append(exitNodes, m.ID)
			default:
				if role == "" || role == "device" {
					deviceNodes = append(deviceNodes, m.ID)
				}
			}
		case osmpbf.WayType:
			wayIDs = append(wayIDs, m.ID)
		}
	}

	if len(entryNodes) > 0 && len(exitNodes) > 0 {
		e, okE := nodes[entryNodes[0]]
		x, okX := nodes[exitNodes[len(exitNodes)-1]]
		return e, x, okE && okX
	}
	if len(deviceNodes) >= 2 {
		e, okE := nodes[deviceNodes[0]]
		x, okX := nodes[deviceNodes[len(deviceNodes)-1]]
		return e, x, okE && okX
	}
	for _, wayID := range wayIDs {
		w, found := ways[wayID]
		if !found {
			continue
		}
		return wayEndpoints(w.nodeIDs, nodes)
	}
	return entry, exit, false
}

func wayToCorridor(externalID string, tags map[string]string, entry, exit coord) normalize.CorridorRecord {
	name := firstNonEmpty(tags["name"], tags["ref"], externalID)
	maxspeed := normalize.ParseMaxspeed(tags)
	speed := int16(50)
	if maxspeed != nil {
		speed = *maxspeed
	}

	midLat := (entry.lat + exit.lat) / 2
	midLon := (entry.lon + exit.lon) / 2

	return normalize.CorridorRecord{
		ExternalID:  externalID,
		Name:        name,
		RegionCode:  normalize.RegionForPoint(midLat, midLon),
		MaxspeedKmh: speed,
		LengthM:     haversineM(entry.lat, entry.lon, exit.lat, exit.lon),
		Direction:   "both",
		Gates: []normalize.CorridorGate{
			{GateType: "entry", Lat: entry.lat, Lon: entry.lon, RadiusM: 100, Sequence: 0},
			{GateType: "exit", Lat: exit.lat, Lon: exit.lon, RadiusM: 100, Sequence: 0},
		},
		SourceTags: tags,
	}
}

func firstNonEmpty(vals ...string) string {
	for _, v := range vals {
		if strings.TrimSpace(v) != "" {
			return v
		}
	}
	return ""
}

func haversineM(lat1, lon1, lat2, lon2 float64) float64 {
	const earthR = 6371000
	rad := math.Pi / 180
	φ1 := lat1 * rad
	φ2 := lat2 * rad
	dφ := (lat2 - lat1) * rad
	dλ := (lon2 - lon1) * rad
	a := math.Sin(dφ/2)*math.Sin(dφ/2) +
		math.Cos(φ1)*math.Cos(φ2)*math.Sin(dλ/2)*math.Sin(dλ/2)
	return 2 * earthR * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
}
