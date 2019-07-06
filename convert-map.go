package main

/*
   convert-map.exe main-boards.tmx child-boards.tmx output.asm

   Convert map data from the Tiled XML save format into the binary
   format for the game.
*/

import (
	"encoding/xml"
	"fmt"
	"io/ioutil"
	"os"
	"strconv"
	"strings"
)

type TilesetXml struct {
	XMLName string    `xml:"tileset"`
	Tiles   []XmlTile `xml:"tile"`
}

type XmlTile struct {
	Id         int           `xml:"id,attr"`
	Properties []XmlProperty `xml:"properties"`
	Image      struct {
		Width  int    `xml:"width,attr"`
		Height int    `xml:"height,attr"`
		Source string `xml:"source,attr"`
	} `xml:"image"`
}

func (xt *XmlTile) GetProperty(name string) string {
	for _, p := range xt.Properties {
		if p.Name == name {
			return p.Value
		}
	}
	return ""
}

func (xt *XmlTile) GetPropertyInt(name string) (int, error) {
	for _, p := range xt.Properties {
		if p.Name == name {
			if p.Type != "int" {
				return 0, fmt.Errorf("Property %q is not an int type.")
			}
			if val, err := strconv.ParseInt(p.Value, 10, 64); err == nil {
				return int(val), nil
			} else {
				return 0, err
			}
		}
	}
	return 0, fmt.Errorf("Property %q not found.")
}

type XmlProperty struct {
	Name  string `xml:"name,attr"`
	Type  string `xml:"type,attr"`
	Value string `xml:"value,attr"`
}

type MapXml struct {
	XMLName  string       `xml:"map"`
	Boards   []XmlLayer   `xml:"layer"`
	Tilesets []XmlTileset `xml:"tileset"`
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
	return strings.Join(layers, "\n")
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

func usage() {
	fmt.Println("Usage: convert-map.exe main-boards.tmx child-boards.tmx output.asm")
}

func main() {
	if len(os.Args) != 4 {
		//fmt.Println("Missing input file")
		usage()
		os.Exit(1)
	}

	rawMain, err := ioutil.ReadFile(os.Args[1])
	if err != nil {
		fmt.Printf("Error reading XML file %q: %v\n", os.Args[1], err)
		os.Exit(1)
	}

	rawChild, err := ioutil.ReadFile(os.Args[2])
	if err != nil {
		fmt.Printf("Error reading XML file %q: %v\n", os.Args[2], err)
	}

	var mapData MapXml
	err = xml.Unmarshal(rawMain, &mapData)
	if err != nil {
		fmt.Printf("Error unmarshaling XML: %s\n", err)
		os.Exit(1)
	}

	var childData MapXml
	err = xml.Unmarshal(rawChild, &childData)
	if err != nil {
		fmt.Printf("Error unmarshaling XML: %s\n", err)
		os.Exit(1)
	}

	//fmt.Printf("%s\n", rawMain)
	fmt.Println("main map data")
	fmt.Println(mapData)
	fmt.Println("child map data")
	fmt.Println(childData)
	//intData := mapData.Boards[0].GetData()
	//fmt.Println(intData)
}
