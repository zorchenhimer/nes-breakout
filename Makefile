
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

WAVE_BMP := $(addsuffix .bmp,$(WAVE_FRAMES))
#WAVE_CHR := $(addsuffix .chr,$(WAVE_FRAMES))
WAVE_CHR = waves.chr

.PHONY: clean default maps tools names travis sample_credits chr cleanimg waves
.PRECIOUS: %.bmp

default: all
all: tools chr bin/$(NAME).nes
names: tools chr clrNames credits_data.i bin/$(NAME).nes
maps: tools chr map_data.i map_child_data.i
tools: $(CONVMAP) $(GENCRED) $(CA) $(LD) $(CHRUTIL)
travis: tools sample_credits chr bin/$(NAME).nes
chr: game.chr credits.chr title.chr hex.chr $(WAVE_CHR)
waves: $(WAVE_CHR)

../subs/*.csv:
	mkdir -p ../subs/
	cp sample-credit-names.csv ../subs/sample-credit-names.csv

clean:
	rm -f bin/*.o bin/*.nes bin/*.map bin/*.dbg *.i *.chr

cleanall:
	rm -f -r bin/
	$(MAKE) -C cc65/ clean
	$(MAKE) -C go-nes/ clean

cleanimg:
	rm -f *.chr *.bmp

clrNames:
	rm -f credits_data.i

%.chr: %.bmp
	$(CHRUTIL) $< -o $@

waves.chr: $(WAVE_BMP)
	$(CHRUTIL) -o $@ $^

$(GENCRED): generate-credits.go
	go build -o $(GENCRED) generate-credits.go

$(BMP2CHR): bmp2chr.go
	go build -o $(BMP2CHR) bmp2chr.go

$(CONVMAP): convert-map/*.go
	cd convert-map && go build -o ../$(CONVMAP)

bin/main.o: $(SOURCES) $(CHR)
	$(CA) $(CAFLAGS) -o $@ main.asm

bin/%.o: %.i
	$(CA) $(CAFLAGS) -o $@ $^

bin/map_data.o: map_data.asm main_map_data.i child_map_data.i
	$(CA) $(CAFLAGS) -o $@ map_data.asm

bin/$(NAME).nes: bin/main.o $(DATA_OBJ)
	$(LD) $(LDFLAGS) -o $@ $^

subscriber-list.csv: sample-credit-names.csv
	cp -u $< $@

credits_data.i: ../subs/*.csv $(GENCRED)
	$(GENCRED) -x zorchenhimer -o $@ -i ../subs/

main_map_data.i: $(CONVMAP) maps/main-boards.tmx
	cd maps && ../$(CONVMAP) main-boards.tmx main ../main_map_data.i

child_map_data.i:$(CONVMAP) maps/child-boards_12x6.tmx
	cd maps && ../$(CONVMAP) child-boards_12x6.tmx child ../child_map_data.i

%.bmp: images/%.aseprite
	aseprite -b $< --save-as $@

$(WAVE_BMP): images/waves.aseprite
	aseprite -b $< --save-as waves_{frame1}.bmp

$(CA):
	$(MAKE) -C cc65/ ca65

$(LD):
	$(MAKE) -C cc65/ ld65

$(CHRUTIL):
	$(MAKE) -C go-nes/ bin/chrutil$(EXT)
