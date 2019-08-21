package main

import (
	"encoding/csv"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

const CLEAR_TILE_ID = "$20"
const CR_EOD = "    .byte $00"

type Group struct {
	Name string
	Label string
	Tenure int
	Subs []Subscriber
}

var SubGroups = []*Group{
	&Group{"1 Year",   "cr_data_1year", 12, []Subscriber{}},
	&Group{"9 Months", "cr_data_9months", 9, []Subscriber{}},
	&Group{"6 Months", "cr_data_6months", 6, []Subscriber{}},
	&Group{"3 Months", "cr_data_3months", 3, []Subscriber{}},
	&Group{"1 Month",  "cr_data_1month", 1, []Subscriber{}},
}

type SortSubs []Subscriber
func (ss SortSubs) Len() int { return len(ss) }
func (ss SortSubs) Less(i, j int) bool { return ss[i].SubDate.Before(ss[j].SubDate) }
func (ss SortSubs) Swap(i, j int) { ss[i], ss[j] = ss[j], ss[i] }

var excludeNames = []string{}

var verbose bool

type OP_CODE int

type Subscriber struct {
	Username string
	Tier     int
	Tenure   int
	Streak   int
	SubDate  time.Time
}

func NewSub(row []string) (*Subscriber, error) {
	if len(row) < 3 {
		return nil, fmt.Errorf("Invalid row: %q", row)
	}

	tier := 1
	if _, err := fmt.Sscanf(row[2], "Tier %d", &tier); err != nil {
		return nil, err
	}

	tenure := 1
	if _, err := fmt.Sscanf(row[3], "%d", &tenure); err != nil {
		return nil, err
	}

	streak := 1
	if _, err := fmt.Sscanf(row[4], "%d", &streak); err != nil {
		return nil, err
	}

	date, err := time.Parse(time.RFC3339, row[1])
	if err != nil {
		return nil, fmt.Errorf("Error parsing time: %v", err)
	}

	return &Subscriber{
		Username: row[0],
		Tier:     tier,
		Tenure:   tenure,
		Streak:   streak,
		SubDate:  date,
	}, nil
}

type SubList []Subscriber

func (sl SubList) Add(sub Subscriber) SubList {
	for _, s := range sl {
		if s.Username == sub.Username {
			if sub.Tenure > s.Tenure {
				if verbose { fmt.Printf("Found newer tenure for %q\n", sub.Username) }
				s.Tenure = sub.Tenure
			}
			return sl
		}
	}

	return append(sl, sub)
}

const asmTemplate = "    .byte $%02X, %q" // prefix, suffix, attribute, name

func (s *Subscriber) AsmString() string {
	length := len(s.Username)
	half := int(length / 2)
	offset := 16 - half
	trailing := 32 - (offset + length)

	chunkLength := length + offset + trailing
	if chunkLength != 32 {
		panic(fmt.Sprintf("Chunklength is not 64 bytes (%d)! %q length:%d offset:%d trailing:%d half:%d", chunkLength, s.Username, length, offset, trailing, half))
	}

	attr_len := (s.Tier-1)<<uint(6) | len(s.Username)
	return fmt.Sprintf(asmTemplate, attr_len, s.Username)
}

func (s Subscriber) String() string {
	return fmt.Sprintf("%s: Tier %d", s.Username, s.Tier)
}

func main() {
	var inputDirectory string
	var outputName string
	var exclude string

	flag.StringVar(&inputDirectory, "i", "", "Directory with input CSV files.")
	flag.StringVar(&outputName, "o", "credits_data.i", "Output assembly file.")
	flag.BoolVar(&verbose, "verbose", false, "Verbose output.")
	flag.StringVar(&exclude, "x", "", "A comma separated list of names to exclude.")
	flag.Parse()

	if len(exclude) > 0 {
		excludeNames = strings.Split(exclude, ",")
	}

	if len(inputDirectory) == 0 {
		fmt.Println("ERROR: Missing input directory")
		os.Exit(1)
	}

	info, err := os.Stat(inputDirectory)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	if !info.IsDir() {
		fmt.Println("Input must be a directory")
		os.Exit(1)
	}

	files, err := filepath.Glob(filepath.Join(inputDirectory, "*.csv"))
	if err != nil {
		fmt.Printf("Error Glob()'ing input directory: %v\n", err)
		os.Exit(1)
	}

	sort.Strings(files)
	if len(files) == 0 {
		fmt.Println("No CSV files found in directory %q", inputDirectory)
		os.Exit(1)
	}

	// reverse the files
	reversed := []string{}
	for i := len(files) - 1; i >= 0; i-- {
		reversed = append(reversed, files[i])
	}

	sl := SubList{}

	for _, inputFile := range reversed {
		if verbose {
			fmt.Printf("Reading file %q\n", inputFile)
		}

		file, err := os.Open(inputFile)
		if err != nil {
			fmt.Println("ERROR: Unable to open subscriber-list.csv: ", err)
			os.Exit(1)
		}

		reader := csv.NewReader(file)

		records, err := reader.ReadAll()
		if err != nil {
			fmt.Println("ERROR: Unable to read subscriber-list.csv: ", err)
			os.Exit(1)
		}

		if verbose {
			fmt.Printf("Found %d records\n", len(records) - 1)
		}

		for _, row := range records[1:] {
			exclude := false
			for _, ex := range excludeNames {
				if ex == strings.ToLower(row[0]) {
					exclude = true
				}
			}

			if !exclude {
				sub, err := NewSub(row)
				if err != nil {
					fmt.Println("WARNING: Error parsing subscriber: ", err)
				} else {
					//fmt.Printf("Parsed sub: %s\n", sub.Username)
					sl = sl.Add(*sub)
					//subList = append(subList, sub)
				}
			}
		}
	}

	if verbose {
		fmt.Println("sub list:")
		for i, s := range sl {
			fmt.Printf("  [%d] %s\n", i, s.Username)
		}
	}

SL_SORT:
	for _, s := range sl {
		for _, g := range SubGroups {
			if s.Tenure >= g.Tenure {
				if verbose { fmt.Printf("Adding %q (%d) to %s\n", s.Username, s.Tenure, g.Name) }
				g.Subs = append(g.Subs, s)
				continue SL_SORT
			}
		}
	}

	for _, g := range SubGroups {
		ss := SortSubs(g.Subs)
		sort.Sort(ss)
		g.Subs = ss
	}

	if verbose {
		for _, g := range SubGroups {
			fmt.Println(g.Name)
			for _, s := range g.Subs {
				fmt.Printf("  T:%d %q\n", s.Tenure, s.Username)
			}
		}
	}

	outFile, err := os.Create(outputName)
	if err != nil {
		fmt.Println("ERROR: Unable to create credits_data.i: ", err)
		os.Exit(1)
	}
	defer outFile.Close()

	fmt.Fprintln(outFile, "; asmsyntax=ca65\n")
	fmt.Fprintln(outFile, ".segment \"PAGE13\"")

	fmt.Fprintln(outFile, "\n.export cr_data_groups\ncr_data_groups:")
	fmt.Fprintln(outFile, "    .word cr_data_attrib")
	for _, g := range SubGroups {
		fmt.Fprintf(outFile, "    .word %s\n", g.Label)
	}

	// TODO: load and generate attribution data
	fmt.Fprintf(outFile, "\n.export CR_GROUP_COUNT\nCR_GROUP_COUNT = %d\n", len(SubGroups) + 1)

	count := 0
	byteLen := 0
	for _, g := range SubGroups {
		fmt.Fprintf(outFile, "\n; %s\n", g.Name)
		fmt.Fprintf(outFile, "%s:\n", g.Label)
		for _, s := range g.Subs {
			fmt.Fprintln(outFile, s.AsmString())
			count++
			byteLen += len(s.Username) + 1
		}
		byteLen++
		fmt.Fprintln(outFile, CR_EOD)
	}

	fmt.Fprintln(outFile, `
; Attributions
cr_data_attrib:
    ; length of label, label, length of name, name
    ; Length's bit 7 denote type of data.  0 for label, 1 for name.
    .byte $0F, "Some sprite work", $86, "Mr Bob"
    .byte $05, "Music", $8C, "Some guy, idk"
    .byte $00 ; NULL is end of list`)

	fmt.Printf("  Names in credits: %d\n  Byte length: %d\n", count, byteLen)
}

// exists returns whether the given file or directory exists or not.
// Taken from https://stackoverflow.com/a/10510783
func exists(path string) bool {
	_, err := os.Stat(path)
	if err == nil {
		return true
	}
	if os.IsNotExist(err) {
		return false
	}
	return true
}
