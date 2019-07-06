# NES Breakout (working title)

A new NES game that takes the traditional breakout gameplay in a different
direction.  Breakout meets Inception.  When you hit a brick you enter a smaller
board that you have to clear to break the brick you entered.

# Building

## Requirements

- Git
- GNU Make
- cc65 toolchain
- Go

Git is used to get the code.  It can be skipped if you download an archive of
the repo.  The others are required.  Go is required for some data conversion
tools (eg, credits and map data).

## How To

```
$ git clone https://github.com/zorchenhimer/nes-breakout.git
$ cd nes-breakout
$ make
```

# Where's the ROM?

I might setup a buildserver eventually, but for now you've gotta build the ROM
yourself.  If you are unable to build (Mac OS may give trouble, idk) I might
give you a current ROM if you ask nicely on [Discord](https://discord.gg/d5tpRSx).
