#!/bin/rdmd

import std.datetime : SysTime;
import std.file;
import std.path;
import std.stdio;
import std.string;
import std.process;
import std.exception;

enum resourceDir = "resources";
enum contentDir  = "content";

struct Converter {
  string targetExt;
  string command;
}

enum converters = [
  "ase"  : Converter("png"  , "aseprite --batch --sheet $(DEST) $(SRC) --data /dev/null"),
	//"svg"  : Converter("png"  , "inkscape $(SRC) --export-png=$(DEST)"                    ),
	//"mmpz" : Converter("ogg"  , "lmms -r $(SRC) -f ogg -b 64 -o $(DEST)"                  ),
  //"ttf"  : Converter("ttf"  , "cp $(SRC) $(DEST)"                                       ),
  //"ogg"  : Converter("ttf"  , "cp $(SRC) $(DEST)"                                       ),
  "tmx"  : Converter("json" , "tiled --export-map $(SRC) $(DEST)"                       ),
];

auto getConverter(string path) {
  string ext = path.extension.chompPrefix(".");
  return converters[ext];
}

unittest {
  assertThrown(getConverter("testfile.asdf"));
  assertNotThrown(getConverter("file.ase"));
}

string getTarget(string path) {
  auto conv = getConverter(path);
  return contentDir ~
    path
    .chompPrefix(resourceDir)
    .stripExtension
    .setExtension(conv.targetExt);
}

unittest {
  assert("resources/image/mr_malwick.ase".getTarget == "content/image/mr_malwick.png");
}

string getCommand(string path) {
  return getConverter(path).command
    .replace("$(SRC)", q{"%s"}.format(path))
    .replace("$(DEST)", q{"%s"}.format(path.getTarget));
}

unittest {
  assert("resources/music/song.mmpz".getCommand ==
      "lmms -r resources/music/song.mmpz -f ogg -b 64 -o resources/music/song.ogg");
}

void convertFile(string path) {
  auto targetPath = path.getTarget;
  auto dir = targetPath.dirName;
  if (!dir.exists) {
    writeln("mkdir ", dir);
    mkdirRecurse(dir);
  }
  writeln("%s -> %s".format(path, targetPath));
  spawnShell(path.getCommand);
}

bool needsUpdate(string srcPath) {
  string targetPath = srcPath.getTarget;
  return (srcPath.timeLastModified >= targetPath.timeLastModified(SysTime.min));
}

bool hasConverter(string path) {
  string ext = path.extension.chompPrefix(".");
  return cast(bool) (ext in converters);
}

void main() {
  writeln("START");
  foreach(path ; resourceDir.dirEntries(SpanMode.depth, false)) {
    if (path.hasConverter && path.needsUpdate) {
      convertFile(path);
    }
  }
  writeln("END");
}
