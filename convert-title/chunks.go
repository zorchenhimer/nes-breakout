package main

import (
	"fmt"
	"strings"
)

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
			if v != 0x00 {
				v -= 1
			}

			if v == 0x00 {
				v = byte(bgTile)
			}
			strVals = append(strVals, fmt.Sprintf("$%02X", v))
		}
	} else {
		v := c.Data[0]
		if v != 0x00 {
			v -= 1
		} else {
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

	return strings.Join(data, "\n")
}
