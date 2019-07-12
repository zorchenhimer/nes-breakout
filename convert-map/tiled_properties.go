package main

import (
	"fmt"
	"strconv"
	"strings"
)

type XmlPropertyList []XmlProperty

type XmlProperty struct {
	XMLName string `xml:"property"`
	Name    string `xml:"name,attr"`
	Type    string `xml:"type,attr"`
	Value   string `xml:"value,attr"`
}

func (xp XmlProperty) String() string {
	return fmt.Sprintf("%s:%q", xp.Name, xp.Value)
}

func (pl XmlPropertyList) String() string {
	p := []string{}
	for _, prop := range pl {
		p = append(p, prop.String())
	}
	return strings.Join(p, " ")
}

func (pl XmlPropertyList) GetProperty(name string) string {
	for _, p := range pl {
		if p.Name == name {
			return p.Value
		}
	}
	return ""
}

func (pl XmlPropertyList) GetBoolProperty(name string, defaultValue bool) bool {
	prop := strings.ToLower(pl.GetProperty(name))
	if prop == "" {
		return defaultValue
	}

	if prop == "false" {
		return false
	}
	return true
}

func (pl XmlPropertyList) GetIntProperty(name string, defaultValue int) int {
	prop := pl.GetProperty(name)
	if prop == "" {
		return defaultValue
	}

	val, err := strconv.ParseInt(prop, 10, 32)
	if err != nil {
		// TODO: log or print this?
		return defaultValue
	}

	return int(val)
}
