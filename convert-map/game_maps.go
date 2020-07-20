package main

import (
	//"encoding/xml"
	"fmt"
	//"io/ioutil"
	//"strconv"
	//"strings"

	"github.com/zorchenhimer/go-tiled"
	//"../../go-tiled"
)

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
	Bricks Bricks

	// List of tile values
	BrickValues []int

	BrickCount     int
	CountSpawn     int
	CountHealth    int
	CountPowerUp   int
	CountPowerDown int
	CountHalf      int

	TileCount int // total number of tiles used
}

func LoadGameMap(layer tiled.Layer, bricks Bricks) (*GameMap, error) {
	gm := &GameMap{
		BrickValues: []int{},
	}

	gm.RandomChildren = layer.Properties.GetBoolProperty("random-children", false)
	gm.RandomDrops = layer.Properties.GetBoolProperty("random-drops", false)
	gm.Health = layer.Properties.GetIntProperty("health", 0)
	gm.Gravity = layer.Properties.GetBoolProperty("gravity", false)
	//gm.Id = layer.Id
	_, err := fmt.Sscanf(layer.Name, "board-%02d", &gm.Id)
	if err != nil {
		return nil, fmt.Errorf("Unable to find board ID for %q: %v", layer.Name, err)
	}

	// TODO: Fix the tile width logic to be more robust and flexable.
	//tiles := strings.Split(layer.Data, ",")
	tileodd := false
	for idx, t := range layer.Data {
		//t = strings.TrimSpace(t)
		//val, err := strconv.ParseInt(t, 10, 32)
		//if err != nil {
		//	return nil, fmt.Errorf("Error parsing tile data: %v", err)
		//}
		val := t
		if val != 0 && val != HalfBrickTiledId && tileodd {
			return nil, fmt.Errorf("Overlapping tile at offset %d in map %q", idx, layer.Name)
		}

		if val == HalfBrickTiledId {
			tileodd = false
		}

		brick, ok := bricks.GetBrick(uint(val))
		if !ok {
			return nil, fmt.Errorf("Brick not found in Bricks: %d", val)
		}

		if !tileodd || val == HalfBrickTiledId {
			gm.Bricks = append(gm.Bricks, brick)

			if brick.Type > BRICK_HEALTH && brick.Type != BRICK_HALF {
				// add powerup/down and child board values
				gm.BrickValues = append(gm.BrickValues, brick.Value)
			}

			switch brick.Type {
			case BRICK_HEALTH:
				gm.CountHealth += 1

			case BRICK_SPAWN:
				gm.CountSpawn += 1

			case BRICK_POWERUP:
				gm.CountPowerUp += 1

			//case BRICK_POWERDOWN:
			//	gm.CountPowerDown += 1

			case BRICK_HALF:
				gm.CountHalf += 1
			}

			if brick.Type == BRICK_UNKNOWN || brick.Type == BRICK_HALF {
				gm.BrickCount++
			} else {
				gm.BrickCount += 2
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

