/// Menu with left/right sliders to adjust numeric values.
module common.options_menu;

import std.format : format;
import common.menu;
import cid;

private enum neutralTint = Color(1f,1f,1f,0.5f);

/// Menu with left/right sliders to adjust numeric values.
class OptionsMenu : Menu {
  // lazy hack, shouldn't rely on looking at the entry names
  private enum Label : string {
    music = "Music",
    sound = "Sound",
  }

  private {
    int[string] _values;
    string      _selection;
  }

  this(Game game) {
    super(
      MenuEntry(Label.music, () {}),
      MenuEntry(Label.sound, () {}));

    _values[Label.music] = 100;
    _values[Label.sound] = 100;

    _selection = Label.music;
  }

  override void moveSelection(Vector2f direction) {
    super.moveSelection(direction);
    adjustValue(direction);
  }

  protected override void drawEntry(
      MenuEntry       entry,
      bool            isSelected,
      Vector2i        center,
      ref TextBatch   textBatch,
      ref SpriteBatch spriteBatch)
  {
      super.drawEntry(entry, isSelected, center, textBatch, spriteBatch);

      Text text;

      text.centered  = true;
      text.color     = neutralTint;
      text.transform = center + Vector2i(120, 0);

      text.text = valueText(entry.text);
      textBatch ~= text;
  }

  private:
  void adjustValue(Vector2f direction) {
    auto value = selectedEntry.text in _values;
    assert(value, "unknown option " ~ _selection);

    if      (direction.x > 0) *value += 5;
    else if (direction.x < 0) *value -= 5;
  }

  string valueText(string name) {
    auto value = name in _values;
    assert(value, "unknown option " ~ name);

    return "%d".format(*value);
  }
}
