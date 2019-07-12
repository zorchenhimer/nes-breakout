package main

import (
	"encoding/xml"
	"fmt"
	"io/ioutil"
	"strings"
)

type TilesetXml struct {
	XMLName string    `xml:"tileset"`
	Tiles   []XmlTile `xml:"tile"`
}

func (tx TilesetXml) String() string {
	tiles := []string{}
	for _, t := range tx.Tiles {
		tiles = append(tiles, t.String())
	}
	return strings.Join(tiles, "\n")
}

type XmlTile struct {
	Id         int             `xml:"id,attr"`
	Properties XmlPropertyList `xml:"properties>property"`
	Image      struct {
		Width  int    `xml:"width,attr"`
		Height int    `xml:"height,attr"`
		Source string `xml:"source,attr"`
	} `xml:"image"`
}

func (xt XmlTile) String() string {
	return fmt.Sprintf("<Tile Id:%d Source:%q Properties:[%s]>", xt.Id, xt.Image.Source, xt.Properties.String())
}

func LoadTileset(filename string) (*TilesetXml, error) {
	rawxml, err := ioutil.ReadFile(filename)
	if err != nil {
		return nil, fmt.Errorf("Error reading tileset file: %v", err)
	}

	var tsxml TilesetXml
	if err = xml.Unmarshal(rawxml, &tsxml); err != nil {
		return nil, fmt.Errorf("Error unmarshaling tilset xml: %v", err)
	}

	return &tsxml, nil
}
