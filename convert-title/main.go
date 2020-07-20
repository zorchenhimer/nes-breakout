package main

import (
	"flag"
	"fmt"
	"os"
	//"strconv"
	"strings"
	"sort"

	"github.com/zorchenhimer/go-tiled"
	//"../../go-tiled"
)

/*
	The data format used for the screens is command based.  The first byte of a
	chunk contains the command in the upper three bits (bits 7-5).  The rest of
	the byte (bits 4-0) contain the length of data minus one, if applicable.

	Commands are as follows:
		CHUNK_RLE  = 1 << 5
		CHUNK_RAW  = 2 << 5
		CHUNK_ADDR = 3 << 5
		CHUNK_SPR  = 4 << 5
		CHUNK_DONE = 0 // no more chunks

	RLE takes a size and a single byte of data.  The data will be repeated SIZE + 1
	number of times.

	RAW takes a size and SIZE + 1 number of bytes to write.

	ADDR sets a new PPU address to write to.  This is used for partial updates
	of the screen.

	SPR defines a sprite layer that should be used with the current background
	layer.

	DONE denotes the end of a screen.

	TTTL LLLL
	T: Type
	L: Length
*/

var bgTile int

type Screen struct {
	LayerNames []string
	IsSprite   bool
	IsOffset   bool		// TODO: Rename this to "UseStrips".

	SpriteLayer string
}

var screens map[string]Screen = map[string]Screen{
	"Hood": Screen{
		LayerNames: []string{"Hood", "TV"},
	},
	"Tv":  Screen{
		LayerNames: []string{"TV"},
		SpriteLayer: "TvSprites",
	},
	"TvStatic":  Screen{
		LayerNames: []string{"TV", "Static"},
		SpriteLayer: "TvSprites",
	},
	"News":  Screen{
		LayerNames: []string{"TV", "News"},
		SpriteLayer: "TvSprites",
	},

	"TvSprites": Screen{
		LayerNames: []string{"SpriteZero", "Sprites"},
		IsSprite:   true,
	},

	// TODO: add a bounding box? or a start address?
	"TextBox": Screen{
		LayerNames: []string{"Text"},
		IsOffset:   true,
	},
}

const LabelPrefix string = "screen_"

func getLayer(data *tiled.Map, name string) (tiled.Layer, error) {
	layers := data.GetLayerByName(name)

	if len(layers) > 0 {
		return layers[0], nil
	}

	return tiled.Layer{}, fmt.Errorf("Layer not found")
}

func processScreen(data *tiled.Map, screenData Screen) (string, error) {
	layers := []tiled.Layer{}

	// Read in the layers needed
	for _, name := range screenData.LayerNames {
		layer, err := getLayer(data, name)
		if err != nil {
			return "", err
		}

		layers = append(layers, layer)
	}

	var err error
	merged := layers[0]

	// Merge layers if there's more than one
	if len(layers) > 1 {
		for _, layer := range layers[1:] {
			merged, err = merged.Merge(layer)
			if err != nil {
				return "", err
			}
		}
	}

	// convert data to chunks
	if screenData.IsSprite {
		return convertSprites(merged.Data).ToAsm(), nil
	}

	var chunks *ChunkList

	if screenData.IsOffset {
		// Offset chunk
		chunks, err = convertOffset(merged.Data)
		if err != nil {
			return "", err
		}
	} else {
		chunks, err = convertLayer(merged.Data, 0)
		if err != nil {
			return "", err
		}
	}

	if screenData.SpriteLayer != "" {
		spChunk := Chunk{
			Type: CHUNK_SPR,
			Data: []byte{0},
			SpriteLabel: LabelPrefix + screenData.SpriteLayer,
		}

		newCL := &ChunkList{}
		newCL.past = []Chunk{spChunk}
		newCL.past = append(newCL.past, chunks.past...)
		chunks = newCL
	}

	return chunks.ToAsm(bgTile), nil
}

// cmd input.xml out.i
func main() {
	//var offset uint = 0

	flag.IntVar(&bgTile, "background-tile", 0, "Replace the background tile ID with a new tile ID")
	flag.IntVar(&bgTile, "b", 0, "Replace the background tile ID with a new tile ID")
	//flag.UintVar(&offset, "id-offset", 0, "Add this offset to the input tile IDs")
	flag.Parse()

	args := flag.Args()
	if len(args) != 2 {
		fmt.Printf("Usage: %s [options] input.xml output.i\n\n", os.Args[0])
		flag.PrintDefaults()
		os.Exit(1)
	}

	data, err := tiled.LoadMap(args[0])
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	file, err := os.Create(args[1])
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	defer file.Close()

	screenLabels := []string{}

	//fmt.Fprintln(file, "CHUNK_RLE = $00\nCHUNK_RAW = $80\nCHUNK_OFFSET = $40\nCHUNK_DONE = $FF\n")
	for label, screen := range screens {
		asm, err := processScreen(data, screen)
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}
		screenLabels = append(screenLabels, label)
		fmt.Fprintf(file, "%s%s:\n%v\n\n", LabelPrefix, label, asm)
	}

	idxFile, err := os.Create(args[1] + ".idx")
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	defer idxFile.Close()

	sort.Strings(screenLabels)

	fmt.Fprintf(idxFile, "; asmsyntax=ca65\n\n.enum ScreenIDs\n")
	for _, label := range screenLabels {
		fmt.Fprintln(idxFile, "    " + label)
	}
	fmt.Fprintf(idxFile, ".endenum\n\n")

	fmt.Fprintf(idxFile, "screen_Index:\n")
	for _, label := range screenLabels {
		fmt.Fprintf(idxFile, "    .word %s%s\n", LabelPrefix, label)
	}
}

type DataRange struct {
	start int
	end int
}

func convertOffset(data []uint32) (*ChunkList, error) {
	if len(data) == 0 {
		return nil, fmt.Errorf("No data to convert!")
	}

	ranges := []DataRange{}

	start := 0
	// find start and end of data
	for i, val := range data {
		if start == 0 && val != 0 {
			start = i
		} else if start != 0 && val == 0 {
			rng := DataRange{start: start, end: i}
			start = 0
			ranges = append(ranges, rng)
		}
	}

	chunks := &ChunkList{past: []Chunk{}}
	for _, r := range ranges {
		//fmt.Printf("ChunkList: %s\n", chunks)
		chunks.AddOffset(uint16(r.start))

		for _, val := range data[r.start:r.end] {
			chunks.Add(byte(val))
		}
	}

	//fmt.Println(chunks.String())

	return chunks, nil
}

func convertLayer(data []uint32, offset uint) (*ChunkList, error) {
	if len(data) == 0 {
		return nil, fmt.Errorf("No data to convert!")
	}

	chunks := &ChunkList{}
	for _, val := range data {
		chunks.Add(byte(val))
	}
	return chunks, nil
}

type Sprite struct {
	X uint8
	Y uint8
	Tile uint8
}

func (s Sprite) ToAsm() string {
	return fmt.Sprintf(".byte %d, $%02X, $00, %d", s.Y, s.Tile, s.X)
}

type SpriteList []Sprite

func (sl SpriteList) ToAsm() string {
	lst := []string{}
	for _, s := range sl {
		lst = append(lst, s.ToAsm())
	}
	return fmt.Sprintf(".byte %d\n%s", len(sl), strings.Join(lst, "\n"))
}

func convertSprites(data []uint32) SpriteList {
	sprites := SpriteList{}
	for i, val := range data {
		if val == 0 {
			continue
		}

		sprite := Sprite {
			X: uint8((i % 32) * 8),
			Y: uint8((i / 32) * 8) - 1, // subtract one for vertical sprite offset
			Tile: uint8(val) - 1, // subtract one to get base-zero ID
		}

		sprites = append(sprites, sprite)
	}

	return sprites
}
