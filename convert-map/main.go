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
)

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

	mapData.SourceFile = os.Args[1]
	childData.SourceFile = os.Args[2]

	mainTilesets := []TilesetXml{}
	for _, ts := range mapData.Tilesets {
		tsRaw, err := ioutil.ReadFile(ts.Source)
		if err != nil {
			fmt.Printf("Unable to load tileset %q: %v\n", ts.Source, err)
			continue
		}
		var tsXml TilesetXml
		if err = xml.Unmarshal(tsRaw, &tsXml); err != nil {
			fmt.Printf("Unable to unmarshal tileset XML %q: %v\n", ts.Source, err)
			continue
		}
		mainTilesets = append(mainTilesets, tsXml)
	}

	for _, ts := range mainTilesets {
		fmt.Println(ts)
	}

	//fmt.Printf("%s\n", rawMain)
	//fmt.Println("main map data")
	fmt.Println(mapData)
	//fmt.Println("child map data")
	//fmt.Println(childData)
	//intData := mapData.Boards[0].GetData()
	//fmt.Println(intData)
}
