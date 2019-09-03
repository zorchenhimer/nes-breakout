# NES Breakout (working title)

A new NES game that takes the traditional breakout gameplay in a different
direction.  Breakout meets Inception.  When you hit a brick you enter a smaller
board that you have to clear to break the brick you entered.

# Building

## Requirements

- Git
- gcc
- Go
- GNU Make
- (optional) Aseprite

Git is required for getting the source code as well as the cc65 and go-nes
dependencies.  It is probably possible to get everything without git, but
you're on you're own in that case.

gcc is used to build ca65 and ld65.  This can be skipped if the cc65 toolchain
is downloaded from a snapshot and placed in the same directory (such that 
`cc65/bin/ca65.exe` as well as `cc65/bin/ld65.exe` exist).

Go is for the utilities to convert map and credits data to assembly.

Make is used for the build orchestration.

All the graphics are worked on in [Aseprite](https://www.aseprite.org/).  This
program is not required to build, but is highly recommended to edit graphics
assets.  The program isn't needed if the bitmap files exist and are newer than
their corresponding `.aseprite` files.

## How To

```
$ git clone --recurse-submodules https://github.com/zorchenhimer/nes-breakout.git
$ cd nes-breakout
$ make
```

# Where's the ROM?

I might setup a build server eventually, but for now you've gotta build the ROM
yourself.  If you are unable to build (Mac OS may give trouble, idk) I might
give you a current ROM if you ask nicely on [Discord](https://discord.gg/d5tpRSx).
