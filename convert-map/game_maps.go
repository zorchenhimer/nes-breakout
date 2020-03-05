package main

import (
	"encoding/xml"
	"fmt"
	"io/ioutil"
	"strconv"
	"strings"

	"github.com/zorchenhimer/go-tiled"
)

const HalfBrickTiledId int64 = 38

type GameMap struct {
	// Map ID.  They will be sorted by this in the ROM.
	Id int

	// Randomly assign child spawn?
	RandomChildren bool

	// Randomly assign powerups/downs?
	RandomDrops bool

	// Start health for the standard tiles.
	Health int

	// Does this map have gravity?  (gravity value is global to the game)
	Gravity bool

	// Bricks and empty tiles take up one element
	// regardless of actual tile size.
	Tiles []Tile

	// List of tile values
	TileValues []int

	BrickCount     int
	CountSpawn     int
	CountHealth    int
	CountPowerUp   int
	CountPowerDown int
	CountHalf      int

	TileCount int // total number of tiles used
}

type TileType int

const (
	TILE_UNKNOWN TileType = iota
	TILE_HEALTH
	TILE_SPAWN
	TILE_POWERUP
	//TILE_POWERDOWN
	TILE_HALF
	//TILE_NOTHING
)

func (tt TileType) String() string {
	switch tt {
	case TILE_HEALTH:
		return "TILE_HEALTH"
	case TILE_SPAWN:
		return "TILE_SPAWN"
	case TILE_POWERUP:
		return "TILE_POWERUP"
	//case TILE_POWERDOWN:
	//	return "TILE_POWERDOWN"
	case TILE_HALF:
		return "TILE_HALF"
	default:
		return "TILE_UNKNOWN"
	}
}

func ParseTileType(value string) TileType {
	switch strings.TrimSpace(strings.ToLower(value)) {
	case "spawn":
		return TILE_SPAWN
	case "powerup":
		return TILE_POWERUP
	//case "powerdown":
	//	return TILE_POWERDOWN
	case "half":
		return TILE_HALF
	default:
		return TILE_HEALTH
	}
}

type Tile struct {
	Id     int
	Type   TileType
	Value  int
	Width  int
	Height int
}

func (t Tile) String() string {
	return fmt.Sprintf("<Tile Id:%d Type:%s Value:%d>", t.Id, t.Type.String(), t.Value)
}

func LoadGameMap(layer tiled.XmlLayer, tileset Tileset) (*GameMap, error) {
	gm := &GameMap{
		TileValues: []int{},
	}

	gm.RandomChildren = layer.Properties.GetBoolProperty("random-children", false)
	gm.RandomDrops = layer.Properties.GetBoolProperty("random-drops", false)
	gm.Health = layer.Properties.GetIntProperty("health", 0)
	gm.Gravity = layer.Properties.GetBoolProperty("gravity", false)
	gm.Id = layer.GetId()

	// TODO: Fix the tile width logic to be more robust and flexable.
	tiles := strings.Split(layer.Data, ",")
	tileodd := false
	for idx, t := range tiles {
		t = strings.TrimSpace(t)
		val, err := strconv.ParseInt(t, 10, 32)
		if err != nil {
			return nil, fmt.Errorf("Error parsing tile data: %v", err)
		}
		if val != 0 && val != HalfBrickTiledId && tileodd {
			return nil, fmt.Errorf("Overlapping tile at offset %d in map %q", idx, layer.Name)
		}

		if val == HalfBrickTiledId {
			tileodd = false
		}

		tile := tileset.GetTile(int(val))
		if !tileodd || val == HalfBrickTiledId {
			if tile == nil {
				return nil, fmt.Errorf("Tile not found in tileset: %d", val)
			}
			gm.Tiles = append(gm.Tiles, *tile)

			if tile.Type > TILE_HEALTH && tile.Type != TILE_HALF {
				// add powerup/down and child board values
				gm.TileValues = append(gm.TileValues, tile.Value)
			}

			switch tile.Type {
			case TILE_HEALTH:
				gm.CountHealth += 1

			case TILE_SPAWN:
				gm.CountSpawn += 1

			case TILE_POWERUP:
				gm.CountPowerUp += 1

			//case TILE_POWERDOWN:
			//	gm.CountPowerDown += 1

			case TILE_HALF:
				gm.CountHalf += 1
			}

			if tile.Type == TILE_UNKNOWN || tile.Type == TILE_HALF {
				gm.TileCount++
			} else {
				gm.TileCount += 2
			}
		}

		if val != 0 && val != HalfBrickTiledId {
			tileodd = true
			gm.BrickCount += 1
		} else {
			tileodd = false
		}
	}

	//fmt.Println(len(gm.Tiles))

	return gm, nil
}

type Tileset []Tile

func NewTileset() Tileset {
	return Tileset{
		Tile{Id: 0, Type: TILE_UNKNOWN, Value: 0},
	}
}

func (tl Tileset) GetTile(id int) *Tile {
	for _, ts := range tl {
		if ts.Id == id {
			return &ts
		}
	}
	return nil
}

func (tl *Tileset) Add(filename string, firstId int) error {
	raw, err := ioutil.ReadFile(filename)
	if err != nil {
		return fmt.Errorf("Error opening tileset xml: %v", err)
	}

	var tsxml tiled.TilesetXml
	if err = xml.Unmarshal(raw, &tsxml); err != nil {
		return fmt.Errorf("Error unmarshaling xml: %v", err)
	}

	for _, t := range tsxml.Tiles {
		tile := Tile{
			Type:   ParseTileType(t.Properties.GetProperty("type")),
			Value:  t.Properties.GetIntProperty("value", -1),
			Width:  t.Image.Width,
			Height: t.Image.Height,
			Id:     t.Id + firstId,
		}

		//fmt.Println("  Added tile:", tile)

		*tl = append(*tl, tile)
	}

	return nil
}

func (tl Tileset) String() string {
	t := []string{}
	for _, tile := range tl {
		t = append(t, tile.String())
	}
	return strings.Join(t, "\n")
}
