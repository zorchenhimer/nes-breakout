
#export PATH := $(PATH):/c/Program Files/Aseprite/

EXT=
ifeq ($(OS),Windows_NT)
EXT=.exe
endif

# Assembler and linker paths
CA = ../cc65/bin/ca65$(EXT)
LD = ../cc65/bin/ld65$(EXT)

CAFLAGS = -g -t nes --color-messages
LDFLAGS = -C $(NESCFG) --dbgfile bin/$(NAME).dbg -m bin/$(NAME).map --color-messages

# Mapper configuration for linker
NESCFG = nes_snrom.cfg

# Tool that generates credits from an input CSV file
GENCRED = bin/generate-credits$(EXT)

# Map data conversion tool
CONVMAP = bin/convert-map$(EXT)

# Tool that generates CHR data from Bitmap images
CHRUTIL = go-nes/bin/chrutil$(EXT)
FONTUTIL = go-nes/bin/fontutil$(EXT)

TITLECONV = bin/convert-title$(EXT)

# Name of the main source file, minus the extension
NAME = breakout

# any CHR files included
CHR = credits.chr game.chr title.chr level-select.chr font.i level-select-ui.chr

# List of all the sources files
SOURCES := main.asm nes2header.inc \
		  game.asm game_ram.asm map_decode.asm \
		  credits.asm credits_ram.asm \
		  title.asm menu_ram.asm level-select.asm \
		  macros.asm \
		  lsbg.i level-select-data.asm gameover.asm \
		  screen-decode.asm screen-data.i \
		  scene-engine.asm scene-data.asm \
		  text-engine.asm text-engine-ram.asm

DATA_OBJ := $(addprefix bin/,credits_data.o map_data.o)

.PHONY: clean default maps tools names travis sample_credits chr cleanimg trav
.PRECIOUS: images/%.bmp

default: all
all: tools chr bin/$(NAME).nes
names: tools chr clrNames credits_data.i bin/$(NAME).nes
maps: tools chr map_data.i map_child_data.i lsbg.i
tools: $(CONVMAP) $(GENCRED) $(CHRUTIL) $(FONTUTIL) $(TITLECONV)
travis: trav tools sample_credits chr $(CA) $(LD) bin/$(NAME).nes
chr: game.chr credits.chr title.chr hex.chr

trav:
	touch images/*.bmp

sample_credits:
	$(GENCRED) -x zorchenhimer -o credits_data.i -i ./credit-names/ -sample-names

clean:
	rm -f bin/*.o bin/*.nes bin/*.map bin/*.dbg bin/*.exe *.i *.chr
	rm -f go-nes/bin/*

cleanall:
	rm -f -r bin/
	$(MAKE) -C cc65/ clean
	$(MAKE) -C go-nes/ clean

cleanimg:
	rm -f *.chr images/*.bmp

clrNames:
	rm -f credits_data.i

%.chr: images/%.bmp
	$(CHRUTIL) $< -o $@

title.chr: images/tv.bmp
	$(CHRUTIL) -o $@ images/tv.bmp --tile-count 32

tv.chr: images/tv.bmp images/hooded.bmp images/news-anchor.bmp
	$(CHRUTIL) -o $@ --remove-duplicates --pad-tiles 256 \
		images/tv.bmp --tile-offset 0 --tile-count 29 \
		images/hooded.bmp --remove-empty \
		images/news-anchor.bmp --remove-empty \
		images/tv.bmp --tile-offset 32 --tile-count 11

tv-lower.chr: images/tv.bmp
	$(CHRUTIL) -o $@ images/tv.bmp --tile-count 12

#level-select.chr: images/level-select.bmp images/level-select-bottom_sprites.bmp
#	$(CHRUTIL) -o $@ $^ --tile-count 17

level-select-ui.chr: images/level-select-just-bottom.bmp
	$(CHRUTIL) -o $@ \
		images/level-select-just-bottom.bmp --remove-duplicates --nt-ids lsbg_ui.i

font.i: images/font.bmp
	$(FONTUTIL) -o $@ -i $< -w font.widths.i -r font.map.i

maps/title.png: title.chr
	$(CHRUTIL) -o $@ $^

maps/tv.png: tv.chr
	$(CHRUTIL) -o $@ $^

maps/tv-lower.png: tv-lower.chr
	$(CHRUTIL) -o $@ $^

$(GENCRED): generate-credits.go
	go build -o $(GENCRED) generate-credits.go

$(CONVMAP): convert-map/*.go
	cd convert-map && go build -o ../$@

$(TITLECONV): convert-title/*.go
	cd convert-title && go build -o ../$@

bin/main.o: $(SOURCES) $(CHR)
	$(CA) $(CAFLAGS) -o $@ main.asm

bin/%.o: %.i
	$(CA) $(CAFLAGS) -o $@ $^

# maps/title.png isn't actually needed here, but putting it here
# removes the need to manually regenerate it.
screen-data.i: maps/title.tmx maps/title.png maps/tv.png maps/tv-lower.png $(TITLECONV)
	cd maps && ../$(TITLECONV) -b 255 title.tmx ../$@

bin/map_data.o: map_data.asm main_map_data.i child_map_data.i
	$(CA) $(CAFLAGS) -o $@ map_data.asm

bin/$(NAME).nes: bin/main.o $(DATA_OBJ)
	$(LD) $(LDFLAGS) -o $@ $^

credits_data.i: $(GENCRED) ./credit-names/*.csv
	$(GENCRED) -x zorchenhimer -o $@ -i ./credit-names/

main_map_data.i: $(CONVMAP) maps/main-boards.tmx
	cd maps && ../$(CONVMAP) main-boards.tmx main ../main_map_data.i

child_map_data.i: $(CONVMAP) maps/child-boards_12x6.tmx
	cd maps && ../$(CONVMAP) child-boards_12x6.tmx child ../child_map_data.i

lsbg.i: $(CONVMAP) maps/lsbg-wang.tmx
	cd maps && ../$(CONVMAP) -levelselect lsbg-wang.tmx ../$@

images/%.bmp: images/%.aseprite
	aseprite -b $< --save-as $@

$(CA):
	$(MAKE) -C cc65/ ca65

$(LD):
	$(MAKE) -C cc65/ ld65

$(CHRUTIL):
	$(MAKE) -C go-nes/ bin/chrutil$(EXT)

$(FONTUTIL):
	$(MAKE) -C go-nes/ bin/fontutil$(EXT)
