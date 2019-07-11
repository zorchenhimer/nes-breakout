package main

import (
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

	// Bricks and empty tiles take up one element
	// regardless of actual tile size.
	Tiles []Tile

	// List of tile spawns.  Used when loading
	// the map into RAM.
	ChildSpawns []int

	// IDs of powerups
	Powerups []int

	// IDs of power-downs
	Powerdowns []int
}

type ChildMap struct {
	Id          int
	RandomDrops bool
	Health      int

	Tiles      [][]Tile
	Powerups   []int
	Powerdowns []int
}

type TileType int
const (
	TILE_HEALTH TileType = iota
	TILE_SPAWN
	TILE_POWERUP
	TILE_POWERDOWN
)

type Tile struct {
	Type TileType
	Value int
}

