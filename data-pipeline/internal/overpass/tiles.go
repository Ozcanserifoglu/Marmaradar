package overpass

import (
	"context"
	"fmt"
	"time"
)

// FetchTiled queries Turkey in 1° tiles to avoid Overpass timeouts and rate limits.
func (c *Client) FetchTiled(ctx context.Context, tiles [][4]float64) (*ImportResult, error) {
	merged := &ImportResult{}
	seenCameras := make(map[string]struct{})
	seenRelations := make(map[int64]struct{})
	seenNodes := make(map[int64]struct{})

	for i, tile := range tiles {
		south, west, north, east := tile[0], tile[1], tile[2], tile[3]
		query := TileQuery(south, west, north, east)

		tileClient := &Client{
			httpClient: c.httpClient,
			query:      query,
		}
		result, err := tileClient.Fetch(ctx)
		if err != nil {
			return merged, fmt.Errorf("tile %d/%d (%.1f,%.1f,%.1f,%.1f): %w", i+1, len(tiles), south, west, north, east, err)
		}

		for _, cam := range result.Cameras {
			if _, dup := seenCameras[cam.ExternalID]; dup {
				continue
			}
			seenCameras[cam.ExternalID] = struct{}{}
			merged.Cameras = append(merged.Cameras, cam)
		}
		for _, rel := range result.Relations {
			if _, dup := seenRelations[rel.ID]; dup {
				continue
			}
			seenRelations[rel.ID] = struct{}{}
			merged.Relations = append(merged.Relations, rel)
		}
		for _, node := range result.Nodes {
			if _, dup := seenNodes[node.ID]; dup {
				continue
			}
			seenNodes[node.ID] = struct{}{}
			merged.Nodes = append(merged.Nodes, node)
		}

		select {
		case <-ctx.Done():
			return merged, ctx.Err()
		case <-time.After(2 * time.Second):
		}
	}
	return merged, nil
}

// BuildNodeMap collects node elements from a tiled import result for corridor conversion.
func BuildNodeMap(elements []overpassElement) map[int64]overpassElement {
	nodes := make(map[int64]overpassElement)
	for _, el := range elements {
		if el.Type == "node" && el.Lat != 0 && el.Lon != 0 {
			nodes[el.ID] = el
		}
	}
	return nodes
}
