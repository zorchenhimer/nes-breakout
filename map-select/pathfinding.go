package main

import (
	"fmt"
	//"strings"
)

type Node struct {
	Name string
	Paths []*Node
	dotted bool
}

// Return a list of all possible paths to the end from the current node.
func (n *Node) GetPaths() []string {

	// No more nodes, just return yourself.
	if len(n.Paths) == 0 {
		return []string{n.Name}
	}

	// foreach node, get it's possible paths
	paths := []string{}
	for _, node := range n.Paths {
		set := node.GetPaths()
		for _, s := range set {
			paths = append(paths, n.Name + " -> " + s)
		}
	}

	return paths
}

func (n *Node) GetDot() []string {

	if len(n.Paths) == 0 || n.dotted {
		n.dotted = true
		return nil
	}
	n.dotted = true

	ret := []string{}
	for _, p := range n.Paths {
		ret = append(ret, fmt.Sprintf("%q->%q;", n.Name, p.Name))
		d := p.GetDot()
		if d != nil {
			ret = append(ret, d...)
		}
	}

	return ret
}

func main() {
	seven := &Node{Name: "7 [15]"}

	sixA := &Node{Name: "6a [12]", Paths: []*Node{seven}}
	sixB := &Node{Name: "6b [13]", Paths: []*Node{seven}}
	sixC := &Node{Name: "6c [14]", Paths: []*Node{seven}}

	fiveA := &Node{Name: "5a [8]", Paths: []*Node{seven}}
	fiveB := &Node{Name: "5b [9]", Paths: []*Node{sixA, sixB}}
	fiveC := &Node{Name: "5c [10]", Paths: []*Node{sixA, sixB}}
	fiveD := &Node{Name: "5d [11]", Paths: []*Node{sixB, sixC}}
	//fiveE := &Node{Name: "5d", Paths: []*Node{sixB}}

	fourA := &Node{Name: "4a [6]", Paths: []*Node{fiveB, fiveC}}
	fourB := &Node{Name: "4b [7]", Paths: []*Node{fiveB, fiveC, fiveD}}

	threeA := &Node{Name: "3a [3]", Paths: []*Node{fourA, fiveA}}
	threeB := &Node{Name: "3b [4]", Paths: []*Node{fourA, fourB}}
	threeC := &Node{Name: "3c [5]", Paths: []*Node{fourB}}

	twoA := &Node{Name: "2a [1]", Paths: []*Node{threeA, threeB}}
	twoB := &Node{Name: "2b [2]", Paths: []*Node{threeB, threeC}}

	one := &Node{Name: "1 [0]", Paths: []*Node{twoA, twoB}}
	//_ = one

	// starfox
	venom:= &Node{Name: "Venom", Paths: []*Node{}}

	area6 := &Node{Name: "Area 6", Paths: []*Node{venom}}
	bolse := &Node{Name: "Bolse", Paths: []*Node{venom}}

	sectorZ := &Node{Name: "SectorZ", Paths: []*Node{area6, bolse}}
	macbeth := &Node{Name: "Macbeth", Paths: []*Node{area6, bolse}}
	titania := &Node{Name: "Titania", Paths: []*Node{bolse}}

	zoness := &Node{Name: "Zoness", Paths: []*Node{sectorZ, macbeth}}
	sectorX := &Node{Name: "SectorX", Paths: []*Node{sectorZ, macbeth, titania}}
	solar := &Node{Name: "Solar", Paths: []*Node{macbeth}}

	aquas := &Node{Name: "Aquas", Paths: []*Node{zoness, solar}}
	katina := &Node{Name: "Katina", Paths: []*Node{solar, sectorX}}
	fichina := &Node{Name: "Fichina", Paths: []*Node{solar, sectorX}}

	mateo := &Node{Name: "Meteo", Paths: []*Node{katina, fichina}}
	sectorY := &Node{Name: "Sector Y", Paths: []*Node{katina, aquas}}

	corneria := &Node{Name: "Corneria", Paths: []*Node{sectorY, mateo}}

	paths := one.GetPaths()
	for i, p := range paths {
		fmt.Printf("[%d] %s\n", i, p)
	}

	fmt.Println("\nDot:")

	for _, d := range corneria.GetDot() {
		fmt.Println(d)
	}

	for _, d := range one.GetDot() {
		fmt.Println(d)
	}
}

