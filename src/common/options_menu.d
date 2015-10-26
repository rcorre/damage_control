/// Menu with left/right sliders to adjust numeric values.
module common.options_menu;

import std.format : format;
import cid;
import constants;
import common.menu;

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
    Game        _game;
    SoundBank   _clickSound; // plays when adjusting options
  }

  this(Game game) {
    super(
      MenuEntry(Label.music, () {}),
      MenuEntry(Label.sound, () {}));

    _game = game;

    _values[Label.music] = 100;
    _values[Label.sound] = 100;

    _selection = Label.music;

    _clickSound = game.audio.getSoundBank(Sounds.menuSelect);
  }

  override void moveSelection(Vector2f direction) {
    super.moveSelection(direction);
    adjustValue(direction);
  }

  protected override void drawEntry(
      MenuEntry          entry,
      bool               isSelected,
      Vector2i           center,
      ref TextBatch      textBatch,
      ref PrimitiveBatch primBatch)
  {
      super.drawEntry(entry, isSelected, center, textBatch, primBatch);

      Text text;

      text.centered  = true;
      text.color     = Tint.neutral;
      text.transform = center + Vector2i(120, 0);

      text.text = valueText(entry.text);
      textBatch ~= text;
  }

  private:
  void adjustValue(Vector2f direction) {
    auto name = selectedEntry.text;
    auto value = name in _values;
    assert(value, "unknown option " ~ _selection);

    if      (direction.x == 0) return;
    else if (direction.x > 0 ) (*value) = (*value + 10).clamp(0, 100);
    else if (direction.x < 0 ) (*value) = (*value - 10).clamp(0, 100);

    switch (name) {
      case Label.music:
        _game.audio.streamMixer.gain = *value / 100f;
        break;
      case Label.sound:
        _game.audio.soundMixer.gain = *value / 100f;
        break;
      default:
        assert(0, "unknown option");
    }

    _clickSound.play();
  }

  string valueText(string name) {
    auto value = name in _values;
    assert(value, "unknown option " ~ name);

    return "%d".format(*value);
  }
}
