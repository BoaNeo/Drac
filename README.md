# DRAC

https://youtu.be/YyMIJoTns1A

## Why

I got into programming back in 1986, at the age of 14-ish, and managed to teach myself 6502 machine code from a book my father got from a co-worker. It was not specifically for the C64, but it did list all the relevant opcodes for the 6502/10 with reasonable descriptions of how they worked, and somehow I finished it with enough of an understanding of machine code programming that I was able to code a bunch of Demos under the DEXION label.

I also started numerous game projects, however, none of them were ever finished. Probably I could have used a few more books :)

In an attempt to rectify this, chasing an old childhood dream, and because I thought it would be fun to re-visit the old breadbox with accumulated knowledge and modern tools, I began writing DRAC sometime early 2025. 

It's no rush, I work on it when I feel like it (which tends to be sunday afternoon for some reason :) ), and I suspect it will be mostly for my own enjoyment, but if anyone finds it useful, for fun, educational purposes or whatever, I'm more than happy to share it :)...

## What

The general game play revolves around a looped, constantly scrolling map (with a little parallax effect because why not), where you control a vampire-ish character named DRAC (duh!). 
DRAC needs to pick up "taxes" from the local village, in the form of a number of gold coins, before dawn (indicated by a count-down timer). The faster you do this, the higher the score for that map.

Once completed it's on to the next village (aka: a new looped section starts).

While running DRAC needs to avoid running into walls and falling into the fire pit at the bottom.

To make life a little easier, DRAC can turn into a bat and fly short distances and he can consume blood to teleport through floors, either up or down. Also look out for buttons that might open an upcoming door.

## How

If you want to give it a run, you can either clone and build the game yourself (I recommend using Sublime with the KickAssembler plugin and VICE - works a treat), or you can simply download the compiled .prg from the bin folder and just dump it into VICE.
