/// Move through menus in the title screen
module title.states.credits;

import cid;
import constants;
import common.menu;
import title.title;

private enum {
  titlePos    = Vector2f(screenW / 2, 30),
  bodyPos     = Vector2f(screenW / 2, 90),
  bodySpacing = Vector2f(0, 30) // space between lines in the body
}

private immutable pages = [
  [
    "Code",
    "by Ryan Roden-Corrent (rcorre)",
    "MIT Licensed",
    "written in D",
    "using Allegro5",
    "D bindings by SeigeLord",
  ],
  [
    "Art",
    "by Ryan Roden-Corrent (rcorre)",
    "Creative Commons with Attribution",
    "created with Aseprite",
  ],
  [
    "Music",
    "by Ryan Roden-Corrent (rcorre)",
    "Creative Commons with Attribution",
    "created with LMMS",
  ],
  [
    "Sound",
    "by Ryan Roden-Corrent (rcorre)",
    "Creative Commons with Attribution",
    "with help from Audacity",
    "and bxfr",
    "and random objects around my apartment",
  ],
  [
    "Font",
    "Mecha by Captain Falcon",
    "Creative Commons Zero (CC0)",
    "but hey, nice to give credit anyways :)",
  ],
];

/// Show the credits screen.
class ShowCredits : State!(Title, Game) {
  private {
    size_t             _pageNum;
    Font               _titleFont;
    Font               _versionFont;
    Array!EventHandler _handlers;
  }

  override {
    void enter(Title title, Game game) {
      _titleFont   = game.graphics.fonts.get(FontSpec.title);
      _versionFont = game.graphics.fonts.get(FontSpec.versionTag);
      _handlers.insert(game.events.onButtonDown("cancel" , &title.popState));
      _handlers ~= game.events.onAxisMoved("move", &moveSelection);
    }

    void exit(Title title, Game game) {
      foreach(h ; _handlers) h.unregister();
    }

    void run(Title title, Game game) {
      auto page = pages[_pageNum];

      auto titleBatch = TextBatch(_titleFont, DrawDepth.menuText);
      auto bodyBatch  = TextBatch(_versionFont, DrawDepth.menuText);

      drawTitle(titleBatch, page[0]);

      foreach(i, line ; page[1..$])
        drawBody(bodyBatch, line, bodyPos + bodySpacing * i);

      game.graphics.draw(titleBatch);
      game.graphics.draw(bodyBatch);
    }
  }

private:
  void moveSelection(Vector2f direction) {
    if (direction.x < 0)
      _pageNum = (_pageNum - 1) % pages.length;
    else if (direction.x > 0)
      _pageNum = (_pageNum + 1) % pages.length;
  }

  private void drawTitle(ref TextBatch batch, string str) {
    Text text;

    text.centered  = true;
    text.color     = Tint.emphasize;
    text.transform = titlePos;
    text.text      = str;

    batch ~= text;
  }

  void drawBody(ref TextBatch batch, string str, Vector2f pos) {
    Text text;

    text.centered  = true;
    text.color     = Tint.subdued;
    text.transform = pos;
    text.text      = str;

    batch ~= text;
  }
}
