Damage Control
===

Damage Control is a game similar to
[Rampart](https://en.wikipedia.org/wiki/Rampart_(video_game)).

# Give it a try!

## Pre-built
Just grab the most recent
[release](https://github.com/rcorre/damage_control/releases) for your platorm,
unpack it, and run the `damage_control` executable.

The binaries are statically linked to Allegro5, but other dependencies are
dynamically linked.

## Build it yourself
You will need a [D compiler](http://dlang.org/download.html) and
[dub](http://code.dlang.org) to compile the game,
[aseprite](http://www.aseprite.org/) to generate the images, and
[lmms](https://lmms.io/) to compile the music. You must use a recent version of
LMMS (one which supports `--loop`, which is not in the current release).

Running `make` should do the trick. This will invoke `dub` to compile the code,
`aseprite` to export `.ase` files to `.png`, and `lmms` to export `.mmpz` files
to `.ogg`. You can usually ignore complaints that `lmms` failed to export a
file. This is a [known bug](https://github.com/LMMS/lmms/issues/588) where
`lmms` will segfault at the end of rendering but still produce the output file.

## Static Linkage
To link statically to Allegro, you can use the `static` dub configuration.
This expects to find static allegro libs in build/lib.
You can produce these from the allegro5 submodule:

- `git submodule update --init` to clone the allegro5 submodule.
- `mkdir build && cd build`
- `cmake ../allegro5 -DSHARED=off`
- `make`
- `cd ..`
- `dub build --config=static`

# Credits:

Written in [D](http://dlang.org).

Using the [Allegro](https://allegro.cc/) game library.

Pixel art created with [Aseprite](http://aseprite.org).

Music created with [LMMS](https://lmms.io).

Maps created with [Tiled](http://mapeditor.org).

Sounds processed with [Audacity](http://www.audacityteam.org/).

Font: [Mecha by Captain Falcon](www.fontspace.com/captain-falcon/mecha)

Some sounds were generated with [bxfr](http://www.bfxr.net/).

Other sounds are just various recordings I took.
