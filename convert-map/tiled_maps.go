package main

import (
	"fmt"
	"strings"
)

type MapXml struct {
	XMLName  string       `xml:"map"`
	Boards   []XmlLayer   `xml:"layer"`
	Tilesets []XmlTileset `xml:"tileset"`
	SourceFile string `xml:"-"`
}

type XmlTileset struct {
	FirstId int    `xml:"firstgid,attr"`
	Source  string `xml:"source,attr"`
}

type XmlLayer struct {
	Id     int    `xml:"id,attr"`
	Name   string `xml:"name,attr"`
	Width  int    `xml:"width,attr"`
	Height int    `xml:"height,attr"`
	Data   string `xml:"data"`
}

func (m MapXml) String() string {
	//return fmt.Sprintf("BGLayer: %s\nBoards: %s", m.BgLayer.String(), m.Boards.String())
	layers := []string{}
	for _, l := range m.Boards {
		layers = append(layers, l.String())
	}
	return fmt.Sprintf("File: %q\n%s", m.SourceFile, strings.Join(layers, "\n"))
}

func (l XmlLayer) String() string {
	return fmt.Sprintf("<Layer Id:%d Name:%q Width:%d Height:%d DataLength:%d>", l.Id, l.Name, l.Width, l.Height, len(l.Data))
}

func (l XmlLayer) GetData() [][]int {
	data := [][]int{}
	row := []int{}
	//split := strings.Split(strings.ReplaceAll(l.Data, "\n", ""), ",")
	split := strings.Split(strings.Replace(l.Data, "\n", "", -1), ",")
	for _, s := range split {
		var i int
		_, err := fmt.Sscanf(s, "%d", &i)
		if err != nil {
			fmt.Printf("Error scanning data: %s", err)
			panic("AAAAAAAAAAAAAAAAA")
		}

		row = append(row, i)
		if len(row) == l.Width {
			data = append(data, row)
			row = []int{}
		}
	}

	return data
}
