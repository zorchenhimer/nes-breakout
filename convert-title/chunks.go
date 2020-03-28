package main

import (
	"fmt"
	"strings"
)

type ChunkType uint8

const (
	CHUNK_RLE  ChunkType = 1 << 5
	CHUNK_RAW  ChunkType = 2 << 5
	CHUNK_ADDR ChunkType = 3 << 5
	CHUNK_SPR  ChunkType = 4 << 5
	CHUNK_DONE ChunkType = 0 // no more chunks
)

const ChunkMaxLength = 32

type Chunk struct {
	Type ChunkType
	Data []byte
	SpriteLabel string
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
	strVals := []string{}
	var t string
	var length int

	switch c.Type {
	case CHUNK_RLE:
		t = "CHUNK_RLE"
		v := c.Data[0]
		if v != 0x00 {
			v -= 1
		} else {
			v = byte(bgTile)
		}
		length = len(c.Data) - 1
		strVals = append(strVals, fmt.Sprintf("$%02X", v))
		return fmt.Sprintf(".byte %s | %d, %s", t, length, strings.Join(strVals, ", "))

	case CHUNK_RAW:
		t = "CHUNK_RAW"
		for _, v := range c.Data {
			if v != 0x00 {
				v -= 1
			}

			if v == 0x00 {
				v = byte(bgTile)
			}
			strVals = append(strVals, fmt.Sprintf("$%02X", v))
		}
		length = len(c.Data) - 1
		return fmt.Sprintf(".byte %s | %d, %s", t, length, strings.Join(strVals, ", "))

	case CHUNK_ADDR:
		t = "CHUNK_ADDR"
		for _, v := range c.Data {
			strVals = append(strVals, fmt.Sprintf("$%02X", v))
		}
		return fmt.Sprintf(".byte %s, %s", t, strings.Join(strVals, ", "))

	case CHUNK_DONE:
		strVals = []string{"$FF"}
		return ".byte CHUNK_DONE"

	case CHUNK_SPR:
		return fmt.Sprintf(".byte CHUNK_SPR, .lobyte(%s), .hibyte(%s)",
			c.SpriteLabel, c.SpriteLabel)

	default:
		panic(fmt.Sprintf("Invalid chunk type: %v", c.Type))
	}
	return "; something went wrong in chunk.ToAsm()"
}

func (c Chunk) Length() int {
	return len(c.Data)
}

type ChunkList struct {
	current *Chunk
	past []Chunk

	prevByte *byte
	isOffset bool
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

func (cl *ChunkList) TileCount() int {
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

func (cl *ChunkList) AddOffset(start, end uint16) error {
	if cl.past != nil || cl.current != nil || cl.prevByte != nil {
		return fmt.Errorf("Offset must be first chunk")
	}

	var address uint16 = 0x2000 + start
	var high uint8 = uint8((address & 0xFF00) >> 8)
	var low uint8 = uint8(address & 0x00FF)

	cl.past = []Chunk{
		Chunk{
			Type: CHUNK_ADDR,
			Data: []byte{high, low},
		},
	}
	cl.isOffset = true

	return nil
}

func (cl *ChunkList) Add(b byte) {
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

			if cl.current.Type == CHUNK_RLE {
				cl.current.Data = append(cl.current.Data, *cl.prevByte)
				cl.past = append(cl.past, *cl.current)
				cl.current = &Chunk{}
			} else {
				cl.past = append(cl.past, *cl.current)
				cl.current = &Chunk{Data: []byte{*cl.prevByte}}
			}

			if *cl.prevByte == b {
				cl.current.Type = CHUNK_RLE
			} else {
				//cl.prevByte = nil
				cl.current.Type = CHUNK_RAW
			}
			cl.prevByte = &b
		}
	}

	// Length limit hit on current
	if cl.current != nil && len(cl.current.Data) >= ChunkMaxLength {
		cl.past = append(cl.past, *cl.current)
		cl.current = nil
	}
}

func (cl ChunkList) ToBytes() []byte {
	if cl.current != nil {
		cl.past = append(cl.past, *cl.current)
	}

	data := []byte{}
	if cl.isOffset {
		data = append(data, byte(CHUNK_DONE))
	}

	for _, c := range cl.past {
		if len(c.Data) == 0 {
			continue
		}
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
		if len(c.Data) == 0 {
			continue
		}
		data = append(data, c.ToAsm(bgTile))
	}
	data = append(data, ".byte CHUNK_DONE")

	return strings.Join(data, "\n")
}
