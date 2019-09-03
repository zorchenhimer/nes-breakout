
export PATH := $(PATH):/c/Program Files/Aseprite/

EXT=
ifeq ($(OS),Windows_NT)
EXT=.exe
endif

# Assembler and linker paths
CA = cc65/bin/ca65$(EXT)
LD = cc65/bin/ld65$(EXT)

CAFLAGS = -g -t nes
LDFLAGS = -C $(NESCFG) --dbgfile bin/$(NAME).dbg -m bin/$(NAME).map

# Mapper configuration for linker
NESCFG = nes_snrom.cfg

# Tool that generates CHR data from Bitmap images
#BMP2CHR = bin/bmp2chr$(EXT)

# Tool that generates credits from an input CSV file
GENCRED = bin/generate-credits$(EXT)
CONVMAP = bin/convert-map$(EXT)

CHRUTIL = go-nes/bin/chrutil$(EXT)

# Name of the main source file, minus the extension
NAME = breakout

# any CHR files included
CHR = credits.chr game.chr title.chr

# List of all the sources files
SOURCES := main.asm nes2header.inc \
		  game.asm game_ram.asm map_decode.asm \
		  credits.asm credits_ram.asm \
		  title.asm

DATA_OBJ := $(addprefix bin/,credits_data.o map_data.o)

.PHONY: clean default maps tools names

default: all
all: tools bin/$(NAME).nes
names: tools clrNames credits_data.i bin/$(NAME).nes
maps: tools map_data.i
tools: $(CONVMAP) $(GENCRED) $(CA) $(LD) $(CHRUTIL)

clean:
	-rm bin/*.o bin/*.nes bin/*.map bin/*.dbg *.i *.chr

cleanall:
	rm -f -r bin/
	$(MAKE) -C cc65/ clean
	$(MAKE) -C go-nes/ clean

clrNames:
	-rm credits_data.i

bin/:
	-mkdir bin

%.chr: %.bmp
	$(CHRUTIL) $< -o $@
#	$(BMP2CHR) -i $< -o $@

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

#bin/game.o: game.asm game_ram.asm

bin/$(NAME).nes: bin/main.o $(DATA_OBJ)
	$(LD) $(LDFLAGS) -o $@ $^

subscriber-list.csv: sample-credit-names.csv
	cp -u $< $@

credits_data.i: ../subs/*.csv $(GENCRED)
	$(GENCRED) -x zorchenhimer -o $@ -i ../subs/ -verbose

map_data.i: $(CONVMAP) maps/main-boards.tmx maps/child-boards.tmx
	cd maps && ../$(CONVMAP) main-boards.tmx child-boards.tmx ../$@

game.bmp: tiles.aseprite
	aseprite -b $< --save-as $@

title.bmp: title-tiles.aseprite
	aseprite -b $< --save-as $@

$(CA):
	$(MAKE) -C cc65/ ca65

$(LD):
	$(MAKE) -C cc65/ ld65

$(CHRUTIL):
	$(MAKE) -C go-nes/ bin/chrutil$(EXT)
