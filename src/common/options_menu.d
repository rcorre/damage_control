/// Menu with left/right sliders to adjust numeric values.
module common.options_menu;

import std.format : format;
import cid;
import constants;
import common.menu;
import common.savedata;

/// Menu with left/right sliders to adjust numeric values.
class OptionsMenu : Menu {
  // lazy hack, shouldn't rely on looking at the entry names
  private enum Label : string {
    music = "Music",
    sound = "Sound",
  }

  private {
    string      _selection;
    Game        _game;
    SoundBank   _clickSound; // plays when adjusting options
    SaveData    _saveData;
  }

  this(Game game, SaveData saveData) {
    super(
      MenuEntry(Label.music, () {}),
      MenuEntry(Label.sound, () {}));

    _game = game;
    _saveData = saveData;

    _selection = Label.music;

    _clickSound = game.audio.getSoundBank(Sounds.menuSelect);
  }

  override void moveSelection(Vector2f direction) {
    super.moveSelection(direction);
    adjustValue(direction);
  }

  override void deactivate() {
    super.deactivate();
    _saveData.save();
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
    auto adjust(ref float val) {
      if      (direction.x > 0 ) return val = clamp(val + .1f, 0, 1);
      else if (direction.x < 0 ) return val = clamp(val - .1f, 0, 1);
      else                       return val;
    }

    switch (selectedEntry.text) {
      case Label.music:
        _game.audio.streamMixer.gain = adjust(_saveData.musicVolume);
        break;
      case Label.sound:
        _game.audio.soundMixer.gain = adjust(_saveData.soundVolume);
        break;
      default:
        assert(0, "unknown option");
    }

    _clickSound.play();
  }

  string valueText(string name) {
    switch (name) {
      case Label.music: return "%3.0f".format(_saveData.musicVolume * 100);
      case Label.sound: return "%3.0f".format(_saveData.soundVolume * 100);
      default: assert(0, "unknown option");
    }
  }
}
