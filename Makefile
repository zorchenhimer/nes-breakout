
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

# Tool that generates credits from an input CSV file
GENCRED = bin/generate-credits$(EXT)

# Map data conversion tool
CONVMAP = bin/convert-map$(EXT)

# Tool that generates CHR data from Bitmap images
CHRUTIL = go-nes/bin/chrutil$(EXT)

TITLECONV = bin/convert-title$(EXT)

# Name of the main source file, minus the extension
NAME = breakout

# any CHR files included
CHR = credits.chr game.chr title.chr level-select.chr

# List of all the sources files
SOURCES := main.asm nes2header.inc \
		  game.asm game_ram.asm map_decode.asm \
		  credits.asm credits_ram.asm \
		  title.asm menu_ram.asm level-select.asm \
		  macros.asm bg_anim.asm \
		  lsbg.i level-select-data.asm gameover.asm \
		  screen-decode.asm screen-data.i

DATA_OBJ := $(addprefix bin/,credits_data.o map_data.o)

WAVE_FRAMES = waves_1 \
			  waves_2 \
			  waves_3 \
			  waves_4 \
			  waves_5 \
			  waves_6 \
			  waves_7 \
			  waves_8 \
			  waves_9 \
			  waves_10 \
			  waves_11 \
			  waves_12 \
			  waves_13 \
			  waves_14 \
			  waves_15

MATRIX14_FRAMES = matrix14_1 \
				  matrix14_2 \
				  matrix14_3 \
				  matrix14_4 \
				  matrix14_5 \
				  matrix14_6 \
				  matrix14_7 \
				  matrix14_8 \
				  matrix14_9 \
				  matrix14_10 \
				  matrix14_11 \
				  matrix14_12 \
				  matrix14_13 \
				  matrix14_14

MATRIX7_FRAMES = matrix7_1 \
				 matrix7_2 \
				 matrix7_3 \
				 matrix7_4 \
				 matrix7_5 \
				 matrix7_6 \
				 matrix7_7 \
				 matrix7_8 \
				 matrix7_9 \
				 matrix7_10 \
				 matrix7_11 \
				 matrix7_12 \
				 matrix7_13 \
				 matrix7_14

WAVE_BMP := $(addprefix images/,$(addsuffix .bmp,$(WAVE_FRAMES)))
MATRIX14_BMP := $(addprefix images/,$(addsuffix .bmp,$(MATRIX14_FRAMES)))
MATRIX7_BMP := $(addprefix images/,$(addsuffix .bmp,$(MATRIX7_FRAMES)))
#WAVE_CHR := $(addsuffix .chr,$(WAVE_FRAMES))
WAVE_CHR = waves.chr
MATRIX14_CHR = matrix14.chr
MATRIX7_CHR = matrix7.chr

.PHONY: clean default maps tools names travis sample_credits chr cleanimg waves trav
.PRECIOUS: images/%.bmp

default: all
all: tools chr bin/$(NAME).nes
names: tools chr clrNames credits_data.i bin/$(NAME).nes
maps: tools chr map_data.i map_child_data.i lsbg.i
tools: $(CONVMAP) $(GENCRED) $(CA) $(LD) $(CHRUTIL)
travis: trav tools sample_credits chr bin/$(NAME).nes
chr: game.chr credits.chr title.chr hex.chr $(WAVE_CHR) $(MATRIX14_CHR) $(MATRIX7_CHR)
waves: $(WAVE_CHR)
newwaves: clean rmwaves waves all

matrix: $(MATRIX14_CHR) $(MATRIX7_CHR)

trav:
	cd convert-map && go get github.com/zorchenhimer/go-tiled
	touch images/*.bmp

sample_credits:
	$(GENCRED) -x zorchenhimer -o credits_data.i -i ./credit-names/ -sample-names

clean:
	rm -f bin/*.o bin/*.nes bin/*.map bin/*.dbg *.i *.chr

cleanall:
	rm -f -r bin/
	$(MAKE) -C cc65/ clean
	$(MAKE) -C go-nes/ clean

cleanimg:
	rm -f *.chr images/*.bmp

clrNames:
	rm -f credits_data.i

rmwaves:
	rm -f images/waves*.bmp

%.chr: images/%.bmp
	$(CHRUTIL) $< -o $@

waves.chr: $(WAVE_BMP)
	$(CHRUTIL) -o $@ $^

matrix14.chr: $(MATRIX14_BMP)
	$(CHRUTIL) --first-plane -o $@ $^

matrix7.chr: $(MATRIX7_BMP)
	$(CHRUTIL) --first-plane -o $@ $^

title.chr: images/tv.bmp images/ascii.bmp
	$(CHRUTIL) -o $@ --pad-tiles 256 images/tv.bmp --tile-count 32 images/ascii.bmp --tile-offset 32

tv.chr: images/tv.bmp images/hooded.bmp images/news-anchor.bmp
	$(CHRUTIL) -o $@ --remove-duplicates --pad-tiles 256 \
		images/tv.bmp --tile-offset 0 --tile-count 32 \
		images/hooded.bmp --remove-empty \
		images/news-anchor.bmp --remove-empty \
		images/tv.bmp --tile-offset 32 --tile-count 5

tv-lower.chr: images/tv.bmp
	$(CHRUTIL) -o $@ images/tv.bmp --tile-count 12

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
	$(TITLECONV) -b 255 $< $@

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

$(WAVE_BMP): images/waves_e.aseprite
	aseprite -b $< --save-as images/waves_{frame1}.bmp

$(MATRIX14_BMP): images/matrix-14.aseprite
	aseprite -b $< --save-as images/matrix14_{frame1}.bmp

$(MATRIX7_BMP): images/matrix-7.aseprite
	aseprite -b $< --save-as images/matrix7_{frame1}.bmp

$(CA):
	$(MAKE) -C cc65/ ca65

$(LD):
	$(MAKE) -C cc65/ ld65

$(CHRUTIL):
	$(MAKE) -C go-nes/ bin/chrutil$(EXT)
