package main

import (
	"flag"
	"fmt"
	"os"
	"strconv"
	"strings"

	"github.com/zorchenhimer/go-tiled"
)

/*
	Intro sequence and menu screen data conversion.

	RLE based.
	First byte:
	- RLE + Length
	- Raw bytes + Length

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
		fmt.Println("Incorrect number of arguments:", len(args))
		os.Exit(1)
	}

	data, err := tiled.LoadMap(args[0])
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	mergedHood := []uint{}
	// first pass, convert hood
	hoodCsv := []string{}
	tvCsv := []string{}
	for _, l := range data.Layers {
		csv := strings.Split(
				strings.ReplaceAll(
					strings.ReplaceAll(l.Data, "\r", ""),
					"\n", ""),
				",")

		if l.Name == "Hood" {
			hoodCsv = csv
		} else if l.Name == "TV" {
			tvCsv = csv
		}
	}

	if len(hoodCsv) != len(tvCsv) {
		fmt.Println("layers have different lengths: %d vs %d", len(hoodCsv), len(tvCsv))
		os.Exit(1)
	}

	for _, val := range hoodCsv {
		i64, err := strconv.ParseUint(val, 10, 32)
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}

		mergedHood = append(mergedHood, uint(i64))
	}

	for i, val := range tvCsv {
		i64, err := strconv.ParseUint(val, 10, 32)
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}
		if i64 == 0 {
			continue
		}

		mergedHood[i] = uint(i64)
	}

	//screens := map[string]*ChunkList{}
	//for _, layer := range data.Layers {
	//	// do a thing

	//	encoded, err := convertLayer(layer)
	//	if err != nil {
	//		fmt.Printf("[%s] %v", layer.Name, err)
	//		os.Exit(1)
	//	}

	//	screens[layer.Name] = encoded
	//	fmt.Printf("%s: %d\n", layer.Name, encoded.TileCount())
	//}

	hoodChunks, err := convertLayer(mergedHood)
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

	// Write to asm file
	//for key, val := range screens {
	//	//fmt.Printf("screen: %s\n%v\n\n", key, val.ToAsm())
	//	fmt.Fprintf(file, "screen_%s:\n%v\n\n", key, val.ToAsm(bgTile))
	//}
}

type ChunkType uint8

const (
	CHUNK_RLE ChunkType = 0x00
	CHUNK_RAW ChunkType = 0x80
)

type Chunk struct {
	Type ChunkType
	Data []byte
}

func (c Chunk) ToBytes() []byte {
	ret := []byte{
		uint8(c.Type) | uint8(len(c.Data)),
	}

	if c.Type == CHUNK_RAW {
		return append(ret, c.Data...)
	}

	return append(ret, c.Data[0])
}

func (c Chunk) ToAsm(bgTile int) string {
	t := "CHUNK_RLE"
	if c.Type == CHUNK_RAW {
		t = "CHUNK_RAW"
	}

	strVals := []string{}
	if c.Type == CHUNK_RAW {
		for _, v := range c.Data {
			if v == 0x00 {
				v = byte(bgTile)
			}
			strVals = append(strVals, fmt.Sprintf("$%02X", v))
		}
	} else {
		v := c.Data[0]
		if v == 0x00 {
			v = byte(bgTile)
		}
		strVals = append(strVals, fmt.Sprintf("$%02X", v))
	}

	return fmt.Sprintf(".byte %s | %d, %s", t, len(c.Data), strings.Join(strVals, ", "))
}

func (c Chunk) Length() int {
	return len(c.Data)
}

type ChunkList struct {
	current *Chunk
	past []Chunk

	prevByte *byte
}

func (cl *ChunkList) Chunks() []Chunk {
	if cl.prevByte != nil {
		cl.Add(*cl.prevByte)
		cl.prevByte = nil
	}

	if cl.current != nil {
		cl.past = append(cl.past, *cl.current)
		cl.current = nil
	}

	return cl.past
}

func (cl ChunkList) TileCount() int {
	count := 0
	for _, c := range cl.past {
		count += c.Length()
	}

	if cl.current != nil {
		count += cl.current.Length()
	}

	if cl.prevByte != nil {
		//fmt.Println("prevByte is non-nil")
		count += 1
	}

	return count
}

func (cl *ChunkList) Add(b byte) {
	if b != 0x00 {
		b -= 1
	}

	if cl.past == nil {
		cl.past = []Chunk{}
	}

	if cl.current == nil {
		// initial state
		if cl.prevByte == nil {
			cl.prevByte = &b

		// initial to RLE
		} else if *cl.prevByte == b {
			cl.current = &Chunk{
				Type: CHUNK_RLE,
				Data: []byte{b},
			}

		// initial to RAW
		} else if *cl.prevByte != b {
			cl.current = &Chunk{
				Type: CHUNK_RAW,
				Data: []byte{*cl.prevByte},
			}

			cl.prevByte = &b
		}
	} else {
		if cl.prevByte == nil {
			panic("Something went wrong.  prevByte is nil with non-nil current.")
		}

		// append RLE
		if *cl.prevByte == b && cl.current.Type == CHUNK_RLE {
			cl.current.Data = append(cl.current.Data, b)

		// append RAW
		} else if *cl.prevByte != b && cl.current.Type == CHUNK_RAW {
			cl.current.Data = append(cl.current.Data, *cl.prevByte)
			cl.prevByte = &b

		// New chunk type
		} else if (*cl.prevByte == b && cl.current.Type == CHUNK_RAW) ||
				  (*cl.prevByte != b && cl.current.Type == CHUNK_RLE) {
			//cl.current.Data = append(cl.current.Data, *cl.prevByte)

			//if cl.current.Type == CHUNK_RLE {
			//	cl.current.Data = append(cl.current.Data, *cl.prevByte)
			//}

			cl.past = append(cl.past, *cl.current)

			cl.current = &Chunk{
				Data: []byte{*cl.prevByte},
			}

			if *cl.prevByte == b {
				cl.current.Type = CHUNK_RLE
			} else {
				cl.prevByte = nil
				cl.current.Type = CHUNK_RAW
			}
			cl.prevByte = &b
		}
	}

	// Length limit hit on current
	if cl.current != nil && len(cl.current.Data) >= 127 {
		cl.past = append(cl.past, *cl.current)
		cl.current = nil
	}
}

func (cl ChunkList) ToBytes() []byte {
	if cl.current != nil {
		cl.past = append(cl.past, *cl.current)
	}

	data := []byte{}
	for _, c := range cl.past {
		data = append(data, c.ToBytes()...)
	}

	return data
}

func (cl ChunkList) ToAsm(bgTile int) string {
	if cl.prevByte != nil {
		cl.Add(*cl.prevByte)
	}

	if cl.current != nil {
		cl.past = append(cl.past, *cl.current)
	}

	data := []string{}
	for _, c := range cl.past {
		data = append(data, c.ToAsm(bgTile))
	}

	return strings.Join(data, "\n")
}

func convertLayer(data []uint) (*ChunkList, error) {
	if len(data) == 0 {
		return nil, fmt.Errorf("No data to convert!")
	}

	chunks := &ChunkList{}
	for _, val := range data {
		chunks.Add(byte(val))
	}
	return chunks, nil
}

