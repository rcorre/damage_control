module engine.graphics.font;

import std.ascii  : newline;
import std.range  : empty;
import std.format : format;
import std.string : toStringz, stripRight;
import std.algorithm;
import std.exception;
import engine.allegro;
import engine.geometry;
import engine.graphics.color;

///
alias Font = ALLEGRO_FONT*;

/**
 * Load a font from a file.
 *
 * Params:
 *  path = filesystem path to the font file
 *  size = size to load the font with
 */
auto loadFont(string path, int size) {
  auto font = al_load_font(path.toStringz, size, 0);
  assert(font, "failed to load font %s size %d".format(path, size));
  return font;
}

/**
 * The height the given text would have when drawn with this font.
 *
 * Each newline adds another multiple of the line height.
 */
int heightOf(Font font, string text) {
  return al_get_font_line_height(font) * (cast(int) text.count(newline) + 1);
}

/**
 * The width the given text would have when drawn with this font.
 *
 * If the text contains newlines, returns the width of the longest line.
 */
int widthOf(Font font, string text) {
  return text
    .splitter(newline)                               // for each line
    .map!(x => al_get_text_width(font, x.toStringz)) // get the drawing width
    .reduce!max                                      // choose the longest
    .ifThrown(0);                                    // return 0 if empty
}

Vector2i sizeOf(Font font, string text) {
  return Vector2i(font.widthOf(text), font.heightOf(text));
}

/// draw text at the given vector position in the given color
void draw(Font font, string text, Color color = Color.black) {
  auto topLeft = Vector2i.zero;
  foreach(line ; text.splitter(newline)) {
    // TODO: use line.ptr instead of toStringz to avoid allocation?
    al_draw_text(font, color, topLeft.x, topLeft.y, 0, line.toStringz);
    topLeft.y += al_get_font_line_height(font);
  }
}

/**
 * Return an array of text lines wrapped at the specified width (in pixels).
 * Text elements are split on whitespace.
 *
 * Similar to std.string.wrap, but with pixels instead of char counts.
 */
string[] wrapText(Font font, string text, int maxLineWidth) {
  // TODO: nogc, return a range
  string currentLine;
  string[] lines;
  foreach(word ; filter!(s => !s.empty)(splitter(text))) {
    if (font.widthOf(currentLine ~ word) > maxLineWidth) {
      lines ~= stripRight(currentLine);
      currentLine = word ~ " ";
    }
    else {
      currentLine ~= (word ~ " ");
    }
  }
  return lines ~ currentLine; // make sure to append last line
}
