package main

import (
	"encoding/xml"
	"fmt"
	"io/ioutil"
	"os"
	"strings"
)

type MapXml struct {
	XMLName	string	`xml:"map"`
	BgLayer XmlLayer `xml:"layer"`
	Boards XmlGroup `xml:"group"`
}

type XmlGroup struct {
	Layers []XmlLayer `xml:"layer"`
}

type XmlLayer struct {
	Id int `xml:"id,attr"`
	Name string `xml:"name,attr"`
	Width int `xml:"width,attr"`
	Height int `xml:"height,attr"`
	Data string `xml:"data"`
}

func (m MapXml) String() string {
	return fmt.Sprintf("BGLayer: %s\nBoards: %s", m.BgLayer.String(), m.Boards.String())
}

func (g XmlGroup) String() string {
	boards := []string{}
	for _, b := range g.Layers {
		boards = append(boards, b.String())
	}

	return strings.Join(boards, "\n")
}

func (l XmlLayer) String() string {
	return fmt.Sprintf("<Layer Id:%d Name:%q Width:%d Height:%d Data:%q>", l.Id, l.Name, l.Width, l.Height, l.Data)
}

func (l XmlLayer) GetData() [][]int {
	data := [][]int{}
	row := []int{}
	split := strings.Split(strings.ReplaceAll(l.Data, "\n", ""), ",")
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

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Missing input file")
		os.Exit(1)
	}

	if len(os.Args) > 2 {
		fmt.Println("Too many input files")
		os.Exit(1)
	}

	raw, err := ioutil.ReadFile(os.Args[1])
	if err != nil {
		fmt.Printf("Error reading XML file: %s\n", err)
		os.Exit(1)
	}

	var data MapXml
	err = xml.Unmarshal(raw, &data)
	if err != nil {
		fmt.Printf("Error unmarshaling XML: %s\n", err)
		os.Exit(1)
	}

	//fmt.Println(data)
	intData := data.Boards.Layers[0].GetData()
	fmt.Println(intData)
}
