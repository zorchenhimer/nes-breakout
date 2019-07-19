
export PATH := $(PATH):../tools/cc65/bin:../../../Program Files/Tiled:/c/Program Files/Aseprite/
#:../../golang/src/github.com/zorchenhimer/go-nes/cmd

EXT=
ifeq ($(OS),Windows_NT)
EXT=.exe
endif

# Assembler and linker paths
CA = ca65
LD = ld65

CAFLAGS = -g -t nes
LDFLAGS = -C $(NESCFG) --dbgfile bin/$(NAME).dbg -m bin/$(NAME).map

# Mapper configuration for linker
NESCFG = nes_snrom.cfg

# Tool that generates CHR data from Bitmap images
BMP2CHR = bin/bmp2chr$(EXT)

# Tool that generates credits from an input CSV file
GENCRED = bin/generate-credits$(EXT)

CONVMAP = bin/convert-map$(EXT)

# Name of the main source file, minus the extension
NAME = breakout

# any CHR files included
CHR = credits.chr game.chr

# List of all the sources files
SOURCES := main.asm nes2header.inc \
		  game.asm map_decode.asm \
		  credits.asm credits_ram.asm

DATA_OBJ := $(addprefix bin/,credits_data.o map_data.o)

# misc
RM = rm

.PHONY: clean default cleanSym symbols pal set_pal map maps utils

default: all
all: utils bin/$(NAME).nes
names: clrNames credits_data.i bin/$(NAME).nes
maps: map_data.i utils
utils: $(CONVMAP) $(GENCRED)

clean:
	-rm bin/*.* *.i *.chr

clrNames:
	-rm credits_data.i

bin/:
	-mkdir bin

%.chr: %.bmp $(BMP2CHR)
	$(BMP2CHR) -i $< -o $@

$(GENCRED): generate-credits.go
	go build -o $(GENCRED) generate-credits.go

$(BMP2CHR): bmp2chr.go
	go build -o $(BMP2CHR) bmp2chr.go

$(CONVMAP): convert-map/*.go
	cd convert-map && go build -o ../$(CONVMAP)

bin/main.o: bin/ $(SOURCES) $(CHR)
	$(CA) $(CAFLAGS) -o $@ main.asm

bin/%.o: %.i
	$(CA) $(CAFLAGS) -o $@ $^

bin/$(NAME).nes: bin/main.o $(DATA_OBJ)
	$(LD) $(LDFLAGS) -o $@ $^

subscriber-list.csv: sample-credit-names.csv
	cp -u $< $@

credits_data.i: subscriber-list.csv $(GENCRED)
	$(GENCRED) -x zorchenhimer -o $@ -i $<

map_data.i: $(CONVMAP) maps/main-boards.tmx maps/child-boards.tmx
	cd maps && ../$(CONVMAP) main-boards.tmx child-boards.tmx ../$@

game.bmp: tiles.aseprite
	aseprite -b $< --save-as $@
