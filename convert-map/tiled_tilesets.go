package main

import (
	"fmt"
	"strings"
	"strconv"
)

type TilesetXml struct {
	XMLName string    `xml:"tileset"`
	Tiles   []XmlTile `xml:"tile"`
}

func (tx TilesetXml) String() string {
	tiles := []string{}
	for _, t := range tx.Tiles{
		tiles = append(tiles, t.String())
	}
	return strings.Join(tiles, "\n")
}

type XmlTile struct {
	Id         int           `xml:"id,attr"`
	Properties struct {
		Props []XmlProperty `xml:"property"`
	} `xml:"properties"`
	Image      struct {
		Width  int    `xml:"width,attr"`
		Height int    `xml:"height,attr"`
		Source string `xml:"source,attr"`
	} `xml:"image"`
}

func (xt XmlTile) String() string {
	props := []string{}
	for _, p := range xt.Properties.Props {
		props = append(props, p.String())
	}
	return fmt.Sprintf("<Tile Id:%d Source:%q Properties:[%s]>", xt.Id, xt.Image.Source, strings.Join(props, "; "))
}

func (xt *XmlTile) GetProperty(name string) string {
	for _, p := range xt.Properties.Props {
		if p.Name == name {
			return p.Value
		}
	}
	return ""
}

func (xt *XmlTile) GetPropertyInt(name string) (int, error) {
	for _, p := range xt.Properties.Props {
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
	XMLName string    `xml:"property"`
	Name  string `xml:"name,attr"`
	Type  string `xml:"type,attr"`
	Value string `xml:"value,attr"`
}

func (xp XmlProperty) String() string {
	return fmt.Sprintf("%s: %q", xp.Name, xp.Value)
}
