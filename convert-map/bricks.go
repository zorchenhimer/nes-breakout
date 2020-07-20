package main

import (
	"fmt"
	"strings"

	"github.com/zorchenhimer/go-tiled"
	//"../../go-tiled"
)

const HalfBrickTiledId uint32 = 38

type BrickType int

const (
	BRICK_UNKNOWN BrickType = iota
	BRICK_HEALTH
	BRICK_SPAWN
	BRICK_POWERUP
	//BRICK_POWERDOWN
	BRICK_HALF
	//BRICK_NOTHING
)

func (bt BrickType) String() string {
	switch bt {
	case BRICK_HEALTH:
		return "BRICK_HEALTH"
	case BRICK_SPAWN:
		return "BRICK_SPAWN"
	case BRICK_POWERUP:
		return "BRICK_POWERUP"
	//case BRICK_POWERDOWN:
	//	return "BRICK_POWERDOWN"
	case BRICK_HALF:
		return "BRICK_HALF"
	default:
		return "BRICK_UNKNOWN"
	}
}

func ParseBrickType(value string) BrickType {
	switch strings.TrimSpace(strings.ToLower(value)) {
	case "spawn":
		return BRICK_SPAWN
	case "powerup":
		return BRICK_POWERUP
	//case "powerdown":
	//	return BRICK_POWERDOWN
	case "half":
		return BRICK_HALF
	default:
		return BRICK_HEALTH
	}
}

type Brick struct {
	Id     uint
	Type   BrickType
	Value  int
	Width  uint
	Height uint
}

func (b Brick) String() string {
	return fmt.Sprintf("<Brick Id:%d Type:%s Value:%d>", b.Id, b.Type.String(), b.Value)
}

type Bricks []Brick

func NewBricks() Bricks {
	return Bricks{
		Brick{Id: 0, Type: BRICK_UNKNOWN, Value: 0},
	}
}

func (b Bricks) GetBrick(id uint) (Brick, bool) {
	for _, brick := range b {
		if brick.Id == id {
			return brick, true
		}
	}
	return Brick{}, false
}

func (b Bricks) Add(firstId uint, tileset tiled.Tileset) (Bricks, error) {
	for _, t := range tileset.Tiles {
		brick := Brick{
			Type:   ParseBrickType(t.Properties.GetStringProperty("type", "health")),
			Value:  t.Properties.GetIntProperty("value", -1),
			Width:  t.Width,
			Height: t.Height,
			Id:     t.Id + firstId,
		}

		//fmt.Println("  Added tile:", tile)

		b = append(b, brick)
	}

	return b, nil
}

func (b Bricks) String() string {
	t := []string{}
	for _, brick := range b {
		t = append(t, brick.String())
	}
	return strings.Join(t, "\n")
}
