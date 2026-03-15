# MANIC MINER

## About

Originally written in 1983 by Matthew Smith. This port is based on the original
ZX Spectrum version, written in C and using the SDL2 library by [fawtytoo](https://github.com/fawtytoo)

This version was created by me as the project started by fawtytoo was archived and I was always keen 
to see this excellent conversion run on a wider variety of platforms.


## Supported Platforms

The game has been converted to love2d to support a wider variety of platforms. It also as had controller support added.


## Video & Audio

I have attempted to love2d to keep the effect below

Some subtle improvements have been made to make the game more enjoyable:

- Per pixel colouring. This eliminates colour clashing.
- 16 colour palette.
- 2 replacement character set fonts; one small, one large.
- The piano keyboard on the title screen has been corrected.
- The title screen has been redrawn in places for a more balanced look.
- The title and in-game music scores have been reproduced and are polyphonic.
- The sound effects are approximately the same as in the original game and
include stereo panning effects.
- To give the music and sound effects a retro feel, a square wave generator is
used to give it a "beepy" sound.

## Cheat mode

Cheat mode is activated just like in the original game by typing the code. Once
activated, switching levels is as simple.

The keyboard numbers 1 to 0 are levels 1 to 10, and the Shift key changes
that to levels 11 to 20. Then press Enter to change level. These key
combinations need to be pressed simultaneously.
