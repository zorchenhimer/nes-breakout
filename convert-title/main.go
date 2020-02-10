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

// cmd input.xml out.i
func main() {
	var bgTile int
	flag.IntVar(&bgTile, "background-tile", 0, "Replace the background tile ID with a new tile ID")
	flag.IntVar(&bgTile, "b", 0, "Replace the background tile ID with a new tile ID")
	flag.Parse()

	args := flag.Args()
	if len(args) != 2 {
		// TODO: print usage
		//fmt.Println("Incorrect number of arguments:", len(args))
		fmt.Printf("Usage: %s [options] input.xml output.i\n\n", os.Args[0])
		flag.PrintDefaults()
		os.Exit(1)
	}

	data, err := tiled.LoadMap(args[0])
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	layersHood := data.GetLayerByName("Hood")
	if len(layersHood) == 0 {
		fmt.Println("Hood layer to found")
	}

	layersTv := data.GetLayerByName("TV")
	if len(layersTv) == 0 {
		fmt.Println("TV layer to found")
	}

	mergedHood, err := layersHood[0].Merge(layersTv[0])
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	layersSprite := data.GetLayerByName("Sprites")
	if len(layersTv) == 0 {
		fmt.Println("Sprites layer to found")
	}

	justTv, err := layersTv[0].Merge(layersSprite[0])
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	hoodChunks, err := convertLayer(mergedHood.Data)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	sprites := convertSprites(layersSprite[0].Data)
	sprites = append([]Sprite{Sprite{X:0xFF,Y:0xFF,Tile:0xFF}} , sprites...)

	fmt.Printf("Sprite count: %d\n", len(sprites))
	for len(sprites) < 64 {
		sprites = append(sprites, Sprite{X:0xFF,Y:0xFF,Tile:0xFF})
	}

	tv, err := convertLayer(justTv.Data)
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

	fmt.Fprintln(file, "CHUNK_RLE = $00\nCHUNK_RAW = $80\n")
	fmt.Fprintf(file, "screen_Hood:\n%v\n\n", hoodChunks.ToAsm(bgTile))
	fmt.Fprintf(file, "screen_Sprites:\n%v\n\n", sprites.ToAsm())
	fmt.Fprintf(file, "screen_Tv:\n%v\n\n", tv.ToAsm(bgTile))
}

func convertLayer(data []uint32) (*ChunkList, error) {
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
