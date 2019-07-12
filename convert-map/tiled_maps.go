package main

import (
	"encoding/xml"
	"fmt"
	"io/ioutil"
	"strings"
)

type MapXml struct {
	XMLName    string       `xml:"map"`
	Boards     []XmlLayer   `xml:"layer"`
	Tilesets   []XmlTileset `xml:"tileset"`
	SourceFile string       `xml:"-"`
}

type XmlTileset struct {
	FirstId int    `xml:"firstgid,attr"`
	Source  string `xml:"source,attr"`
}

type XmlLayer struct {
	Id         int             `xml:"id,attr"`
	Name       string          `xml:"name,attr"`
	Width      int             `xml:"width,attr"`
	Height     int             `xml:"height,attr"`
	Data       string          `xml:"data"`
	Properties XmlPropertyList `xml:"properties>property"`
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
	props := []string{}
	//for _, p := range l.Properties.Props {
	for _, p := range l.Properties {
		props = append(props, p.String())
	}

	return fmt.Sprintf("<Layer Id:%d Name:%q Width:%d Height:%d DataLength:%d Properties:[%s]>", l.Id, l.Name, l.Width, l.Height, len(l.Data), strings.Join(props, "; "))
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

func (xl XmlLayer) GetId() int {
	var id int
	_, err := fmt.Sscanf(strings.ToLower(xl.Name), "board-%d", &id)
	if err != nil {
		return -1
	}
	return id
}

func LoadMap(filename string) (*MapXml, error) {
	rawxml, err := ioutil.ReadFile(filename)
	if err != nil {
		return nil, fmt.Errorf("Error reading XML file: %v\n", err)
	}

	var mapData MapXml
	err = xml.Unmarshal(rawxml, &mapData)
	if err != nil {
		return nil, fmt.Errorf("Error unmarshaling XML: %v\n", err)
	}

	mapData.SourceFile = filename

	return &mapData, nil
}
