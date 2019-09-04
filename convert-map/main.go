package main

/*
   convert-map.exe main-boards.tmx child-boards.tmx output.asm

   Convert map data from the Tiled XML save format into the binary
   format for the game.
*/

import (
	"fmt"
	"os"
	"strings"
)

func usage() {
	fmt.Println("Usage: convert-map.exe main-boards.tmx label_prefix output.asm")
}

func main() {
	if len(os.Args) != 4 {
		//fmt.Println("Missing input file")
		usage()
		os.Exit(1)
	}

	mapData, err := LoadMap(os.Args[1])
	if err != nil {
		fmt.Printf("Unable to load main map %q: %v\n", os.Args[1], err)
		os.Exit(1)
	}

	prefix := os.Args[2]

	mainTilesets := NewTileset()
	for _, ts := range mapData.Tilesets {
		err := mainTilesets.Add(ts.Source, ts.FirstId)
		if err != nil {
			fmt.Printf("Unable to load tileset %q: %v\n", ts.Source, err)
			os.Exit(1)
		}
	}

	//fmt.Println(mainTilesets)

	//fmt.Println(mapData)
	//fmt.Println(childData)

	//fmt.Println("Main tileset:")
	//fmt.Println(mainTilesets)

	mainMaps := []*GameMap{}
	//childMaps := []*GameMap{}

	layerSizes := [][]int{}

	for _, m := range mapData.Boards {
		if m.GetId() < 0 {
			fmt.Printf("Skipping layer %q\n", m.Name)
			continue
		}

		gm, err := LoadGameMap(m, mainTilesets)
		if err != nil {
			fmt.Printf("Unable to load map %q: %v\n", m.Name, err)
			os.Exit(1)
		}
		mainMaps = append(mainMaps, gm)
		layerSizes = append(layerSizes, []int{m.Width, m.Height})
	}

	outfile, err := os.Create(os.Args[3])
	if err != nil {
		fmt.Printf("Unable to open output file %q for writing: %v\n", os.Args[3], err)
		os.Exit(1)
	}
	defer outfile.Close()

	fmt.Fprintln(outfile, "; asmsyntax=ca65\n")
	fmt.Fprintln(outfile, ".segment \"PAGE01\"")
	fmt.Fprintf(outfile, ".export %s_Index_Maps, %s_BOARD_DATA_WIDTH, %s_BOARD_DATA_HEIGHT\n", prefix, prefix, prefix)
	fmt.Fprintf(outfile, ".export %s_NUMBER_OF_MAPS\n%s_NUMBER_OF_MAPS = %d\n\n%s_Index_Maps:\n", prefix, prefix, len(mainMaps), prefix)
	for i := 0; i < len(mainMaps); i++ {
		fmt.Fprintf(outfile, "    .word %s_Meta_Map%02d\n", prefix, i)
	}
	fmt.Fprintln(outfile, "")

	fmt.Println("Map data lengths:")
	// %0        No brick
	// %10       Standard brick (health)
	// %110      Child spawn
	// %1110     Powerup
	// %11110    PowerDown
	for _, m := range mainMaps {
		//fmt.Println("Map:", m.Id)
		data := []string{}

		currentByte := uint8(0)
		count := 0
		for _, tile := range m.Tiles {
			for i := 0; i < int(tile.Type); i++ {
				currentByte = (currentByte << uint8(1)) | uint8(1)
				count += 1
				if count >= 8 {
					data = append(data, fmt.Sprintf("%%%08b", currentByte))
					currentByte = uint8(0)
					count = 0
				}
			}

			currentByte = (currentByte << uint8(1))
			count += 1
			if count >= 8 {
				data = append(data, fmt.Sprintf("%%%08b", currentByte))
				currentByte = uint8(0)
				count = 0
			}
		}
		// Pad the last byte
		for ; count < 8; count++ {
			currentByte = (currentByte << uint8(1))
		}
		data = append(data, fmt.Sprintf("%%%08b", currentByte))

		tileValues := []string{}
		for _, val := range m.TileValues {
			tileValues = append(tileValues, fmt.Sprintf("$%02X" ,val))
		}
		if len(tileValues) == 0 {
			tileValues = append(tileValues, "$00")
		}

		fmt.Fprintf(outfile, "%s_Meta_Map%02d:\n    .word %s_Data_Map%02d_Tiles\n    .word %s_Data_Map%02d_TileValues\n    .byte %d\n\n",
			prefix, m.Id,
			prefix, m.Id,
			prefix, m.Id, m.Health)

		fmt.Fprintf(outfile, "%s_Data_Map%02d_TileValues:\n", prefix, m.Id)
		fmt.Fprintf(outfile, "    .byte %s\n", strings.Join(tileValues, ", "))
		fmt.Fprintf(outfile, "%s_Data_Map%02d_Tiles:\n", prefix, m.Id)
		fmt.Fprintf(outfile, "    .byte %s\n\n", strings.Join(data, ", "))

		if len(tileValues) > 256 {
			fmt.Printf("Board %d has too much value data! %d bytes\n", m.Id, len(tileValues))
			os.Exit(1)
		}

		if len(data) > 256 {
			fmt.Printf("Board %d has too much data! %d bytes\n", m.Id, len(data))
			os.Exit(1)
		}

		fmt.Printf("  Board %d: % 4d% 4d% 4d | % 4d% 4d% 4d% 4d\n",
			m.Id, len(tileValues), len(data), m.BrickCount,
			m.CountHealth, m.CountSpawn, m.CountPowerUp, m.CountPowerDown,
		)
	}

	width := 0
	height := 0

	for id, layer := range layerSizes {

		if width == 0 && height == 0 {
			width = layer[0]
			height = layer[1]
		} else if width != layer[0] || height != layer[1]  {
			fmt.Printf("  [%d] %d, %d vs %d %d\n", id, width, height, layer[0], layer[1])
			fmt.Printf("Missmatched layer sizes!")
			os.Exit(1)
		}
	}

	fmt.Fprintf(outfile, "%s_BOARD_DATA_WIDTH = %d\n%s_BOARD_DATA_HEIGHT = %d\n", prefix, width, prefix, height)
}
