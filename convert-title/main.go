package main

import (
	"flag"
	"fmt"
	"os"
	//"strconv"
	"strings"

	"github.com/zorchenhimer/go-tiled"
)

/*
	The data format used for the screens is a combination of run-length and
	raw data, with a length count in the first byte.

	The data is split up into chunks.  Each chunk is either run-length or
	raw data.  The first byte of a chunk holds both the type and the length
	of data.

	The first bit determines the chunk type.  If bit 7 is set, the chunk is
	a raw data chunk.  It is a run-length chunk otherwise.  Bits 6-0 hold
	the length of the data.

	A run-length chunk will always be two bytes long.  The first byte is the
	chunk type and length, while the second byte is the data to be repeated.

	A raw data chunk is N + 1 bytes long.  The first byte is the chunk type
	and length (just like the RLE byte), and it is followed by a list of data.

	TLLL LLLL
	T: Type
	L: Length
*/

var bgTile int

type Screen struct {
	LayerNames []string
	IsSprite   bool
	IsOffset   bool		// TODO: Rename this to "UseStrips".
}

var screens map[string]Screen = map[string]Screen{
	"screen_Hood": Screen{
		LayerNames: []string{"Hood", "TV"},
	},
	"screen_Tv":  Screen{
		LayerNames: []string{"TV"},
	},
	"screen_TvStatic":  Screen{
		LayerNames: []string{"TV", "Static"},
	},
	"screen_News":  Screen{
		LayerNames: []string{"TV", "News"},
	},

	"screen_Sprites": Screen{
		LayerNames: []string{"SpriteZero", "Sprites"},
		IsSprite:   true,
	},

	// TODO: add a bounding box? or a start address?
	"screen_TextBox": Screen{
		LayerNames: []string{"Text"},
		IsOffset:   true,
	},
}

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
		sprites := convertSprites(merged.Data)

		for len(sprites) < 64 {
			sprites = append(sprites, Sprite{X:0xFF,Y:0xFF,Tile:0xFF})
		}

		return sprites.ToAsm(), nil
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

	//fmt.Fprintln(file, "CHUNK_RLE = $00\nCHUNK_RAW = $80\nCHUNK_OFFSET = $40\nCHUNK_DONE = $FF\n")
	for label, screen := range screens {
		asm, err := processScreen(data, screen)
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}
		fmt.Fprintf(file, "%s:\n%v\n\n", label, asm)
	}

}

func convertOffset(data []uint32) (*ChunkList, error) {
	if len(data) == 0 {
		return nil, fmt.Errorf("No data to convert!")
	}

	start := uint16(0)
	end := uint16(0)
	// find start and end of data
	for i, val := range data {
		if start == 0 && val != 0 {
			start = uint16(i)
		} else if start != 0 && val == 0 {
			end = uint16(i - 1)
		}
	}

	chunks := &ChunkList{}
	chunks.AddOffset(start, end)

	for _, val := range data[start:end] {
		chunks.Add(byte(val))
	}

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
	return strings.Join(lst, "\n")
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
