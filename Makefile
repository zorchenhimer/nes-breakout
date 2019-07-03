
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
BMP2CHR = bmp2chr$(EXT)

# Tool that generates credits from an input CSV file
GENCRED = generate-credits$(EXT)

# Name of the main source file, minus the extension
NAME = breakout

# any CHR files included
CHR = credits.chr game.chr

# List of all the sources files
SOURCES = main.asm nes2header.inc \
		  game.asm \
		  credits.asm credits_ram.asm credits_data.i

# misc
RM = rm

.PHONY: clean default cleanSym symbols pal set_pal map

default: all
all: bin/$(NAME).nes
names: clrNames credits_data.i bin/$(NAME).nes

clean:
	-$(RM) bin/*.* credits_data.i *.chr $(BMP2CHR) $(GENCRED)

clrNames:
	-$(RM) credits_data.i

bin/:
	-mkdir bin

%.chr: %.bmp
	./bmp2chr -i $< -o $@

$(GENCRED): generate-credits.go
	go build generate-credits.go

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

credits_data.i: $(GENCRED)
	./$(GENCRED) -x zorchenhimer -o credits_data.i -i subscriber-list.csv

map:
	tiled.exe --export-map json map.tmx map-exported.json
