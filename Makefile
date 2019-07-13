
export PATH := $(PATH):../tools/cc65/bin:../../../Program Files/Tiled
#:../../golang/src/github.com/zorchenhimer/go-nes/cmd

EXT=
ifeq ($(OS),Windows_NT)
EXT=.exe
endif

# Assembler and linker paths
CA = ca65
LD = ld65

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
SOURCES = main.asm nes2header.inc \
		  game.asm map_decode.asm map_data.i \
		  credits.asm credits_ram.asm credits_data.i

# misc
RM = rm

.PHONY: clean default cleanSym symbols pal set_pal map maps

default: all
all: bin/$(NAME).nes
names: $(GENCRED) clrNames credits_data.i bin/$(NAME).nes
maps: $(CONVMAP) map_data.i

clean:
	-$(RM) bin/*.* *.i *.chr

clrNames:
	-$(RM) credits_data.i

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

bin/$(NAME).o: bin/ $(SOURCES) $(CHR)
	$(CA) -g \
		-t nes \
		-o bin/$(NAME).o\
		main.asm

bin/$(NAME).nes: bin/$(NAME).o $(NESCFG)
	$(LD) -o bin/$(NAME).nes \
		-C $(NESCFG) \
		--dbgfile bin/$(NAME).dbg \
		bin/$(NAME).o

subscriber-list.csv: sample-credit-names.csv
	cp -u $< $@

credits_data.i: $(GENCRED) subscriber-list.csv
	$(GENCRED) -x zorchenhimer -o $@ -i subscriber-list.csv

map_data.i: $(CONVMAP) maps/main-boards.tmx maps/child-boards.tmx
	cd maps && ../$(CONVMAP) main-boards.tmx child-boards.tmx ../$@
