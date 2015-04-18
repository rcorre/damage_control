module title.title;

import dau.all;

class Title : Scene!Title {
  this(GameSettings settings) {
    System!Title[] systems = [];
    Sprite[string] cursorSprites = [
      "inactive" : new Animation("gui/cursor", "inactive", Animation.Repeat.loop),
      "active"   : new Animation("gui/cursor", "active", Animation.Repeat.loop),
      "ally"     : new Animation("gui/cursor", "ally", Animation.Repeat.loop),
      "enemy"    : new Animation("gui/cursor", "enemy", Animation.Repeat.loop),
      "wait"     : new Animation("gui/cursor", "wait", Animation.Repeat.loop),
    ];
    super(systems, cursorSprites, settings);
    cursor.setSprite("inactive");
    playMusicTrack("menu", true);
  }

  override {
    void enter() {
    }
  }
}
