package main

/*
   convert-map.exe main-boards.tmx child-boards.tmx output.asm

   Convert map data from the Tiled XML save format into the binary
   format for the game.
*/

import (
	"flag"
	"fmt"
	"os"
	//"strconv"
	"strings"
	//"sort"

	"github.com/zorchenhimer/go-tiled"
	//"../../go-tiled"
)

func usage() {
	fmt.Println("Usage: convert-map.exe main-boards.tmx label_prefix output.asm")
}

func main() {
	var levelselect bool
	var err error
	flag.BoolVar(&levelselect, "levelselect", false, "Convert level select background")
	flag.Parse()

	if levelselect {
		if err := doLevelSelectInstead(); err != nil {
			fmt.Println(err)
			os.Exit(1)
		}
		os.Exit(0)
	}

	if len(os.Args) != 4 {
		//fmt.Println("Missing input file")
		usage()
		os.Exit(1)
	}

	mapData, err := tiled.LoadMap(os.Args[1])
	if err != nil {
		fmt.Printf("Unable to load main map %q: %v\n", os.Args[1], err)
		os.Exit(1)
	}

	prefix := os.Args[2]

	bricks := NewBricks()
	//mainTilesets := NewTileset()
	for _, ts := range mapData.Tilesets {
		//fmt.Printf("map tileset: %v\n", ts)
		bricks, err = bricks.Add(ts.FirstGid, ts)
		if err != nil {
			fmt.Printf("Unable to add tileset %q: %v\n", ts.Source, err)
			os.Exit(1)
		}
	}

	//fmt.Println(mainTilesets)

	//fmt.Println(mapData)
	//fmt.Println(childData)

	//fmt.Println("Main tileset:")
	//fmt.Println(mainTilesets)

	mainMaps := map[int]*GameMap{}
	//childMaps := []*GameMap{}

	layerSizes := map[int][]uint{}

	for _, m := range mapData.Layers {
		if m.Id < 0 {
			fmt.Printf("Skipping layer %q\n", m.Name)
			continue
		}

		gm, err := LoadGameMap(m, bricks)
		if err != nil {
			fmt.Printf("Unable to load map %q: %v\n", m.Name, err)
			os.Exit(1)
		}
		mainMaps[m.Id] = gm
		layerSizes[m.Id] = []uint{m.Width, m.Height}
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
	//keys := []int{}
	//for k, _ := range mainMaps {
	//	keys = append(keys, k)
	//}

	//sort.Ints(keys)

	//for _, i := range keys {
	for i := 0; i < len(mainMaps); i++ {
		fmt.Fprintf(outfile, "    .word %s_Meta_Map%02d\n", prefix, i)
	}
	fmt.Fprintln(outfile, "")

	fmt.Println("Map data lengths:")
	// %0        No brick
	// %10       Standard brick (health)
	// %110      Child spawn
	// %1110     Powerup
	// %11110    PowerDown  ;; nope
	// %11110   Half brick
	for _, m := range mainMaps {
	//for _, i := range keys {
		//m := mainMaps[i]
		//fmt.Println("Map:", m.Id)
		data := []string{}

		currentByte := uint8(0)
		count := 0
		for _, brick := range m.Bricks {
			for i := 0; i < int(brick.Type); i++ {
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

		brickValues := []string{}
		for _, val := range m.BrickValues {
			brickValues = append(brickValues, fmt.Sprintf("$%02X", val))
		}
		if len(brickValues) == 0 {
			brickValues = append(brickValues, "$00")
		}

		flags := m.Health | (BoolToAsm(m.Gravity) << 7) | (BoolToAsm(m.RandomDrops) << 6) | (BoolToAsm(m.RandomChildren) << 5)

		fmt.Fprintf(outfile, "%s_Meta_Map%02d:\n    .word %s_Data_Map%02d_Tiles\n    .word %s_Data_Map%02d_TileValues\n    .byte %%%08b\n\n",
			prefix, m.Id,
			prefix, m.Id,
			prefix, m.Id,
			flags,
		)

		fmt.Fprintf(outfile, "%s_Data_Map%02d_TileValues:\n", prefix, m.Id)
		fmt.Fprintf(outfile, "    .byte %s\n", strings.Join(brickValues, ", "))
		fmt.Fprintf(outfile, "%s_Data_Map%02d_Tiles:\n", prefix, m.Id)
		fmt.Fprintf(outfile, "    .byte %s\n\n", strings.Join(data, ", "))

		if len(brickValues) > 256 {
			fmt.Printf("Board %d has too much value data! %d bytes\n", m.Id, len(brickValues))
			os.Exit(1)
		}

		if len(data) > 256 {
			fmt.Printf("Board %d has too much data! %d bytes\n", m.Id, len(data))
			os.Exit(1)
		}

		fmt.Printf("  Board %d: % 4d% 4d% 4d | % 4d% 4d% 4d% 4d\n",
			m.Id, len(brickValues), len(data), m.BrickCount,
			m.CountHealth, m.CountSpawn, m.CountPowerUp, m.CountPowerDown,
		)
	}

	var (
		width uint
		height uint
	)

	for id, layer := range layerSizes {

		if width == 0 && height == 0 {
			width = layer[0]
			height = layer[1]
		} else if width != layer[0] || height != layer[1] {
			fmt.Printf("  [%d] %d, %d vs %d %d\n", id, width, height, layer[0], layer[1])
			fmt.Printf("Missmatched layer sizes!")
			os.Exit(1)
		}
	}

	fmt.Fprintf(outfile, "%s_BOARD_DATA_WIDTH = %d\n%s_BOARD_DATA_HEIGHT = %d\n", prefix, width, prefix, height)
}

func doLevelSelectInstead() error {
	fmt.Println("doing level select")

	inputName := flag.Arg(0)
	if inputName == "" {
		return fmt.Errorf("Missing input file")
	}

	outputName := flag.Arg(1)
	if outputName == "" {
		return fmt.Errorf("Missing output file")
	}

	xml, err := tiled.LoadMap(inputName)
	if err != nil {
		return err
	}

	if len(xml.Layers) < 3 {
		return fmt.Errorf("not enough layers")
	}

	one, two := []string{}, []string{}

	//data := strings.Split(strings.ReplaceAll(xml.Layers[2].Data, "\n", ""), ",")
	for i := 0; i < len(xml.Layers[2].Data); i++ {
		//num, err := strconv.ParseInt(data[i], 10, 32)
		//if err != nil {
		//	return fmt.Errorf("Invalid number in map data at offset %d: %q", i, data[i])
		//}
		num := xml.Layers[2].Data[i]

		if num != 0 {
			num -= 1
		} else {
			num = 0xFC
		}

		if i % 64 < 32 {
			one = append(one, fmt.Sprintf("%d", num))
		} else {
			two = append(two, fmt.Sprintf("%d", num))
		}
	}

	fmt.Printf("nametable 0: %d\nnametable 1: %d\ntotal: %d\n", len(one), len(two), (len(one) + len(two)))

	outfile, err := os.Create(outputName)
	if err != nil {
		return err
	}
	defer outfile.Close()

	fmt.Fprintf(outfile, "data_LS_BackgroundA:\n    .byte ")
	fmt.Fprintf(outfile, strings.Join(one, ", "))
	fmt.Fprintf(outfile, "\n\ndata_LS_BackgroundB:\n    .byte ")
	fmt.Fprintf(outfile, strings.Join(two, ", "))
	fmt.Fprintf(outfile, "\n")
	return nil
}

func BoolToAsm(value bool) int {
	if value {
		return 1
	}
	return 0
}
