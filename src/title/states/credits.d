/// Move through menus in the title screen
module title.states.credits;

import std.typecons;

import cid;
import constants;
import common.menu;
import title.title;

private enum {
  titlePos    = Vector2f(screenW / 2, 40),
  leftMenuX   = -screenW / 2,
  centerMenuX = screenW / 2,
  rightMenuX  = screenW * 3 / 2,
  bodySpacing = Vector2f(0, 40) // space between lines in the body
}

private immutable pageInfo = [
  tuple("Code", [
        MenuEntry("by Ryan Roden-Corrent (rcorre)", null),
        MenuEntry("MIT Licensed", null),
        MenuEntry("written in D", null),
        MenuEntry("using Allegro5", null),
        MenuEntry("D bindings by SeigeLord", null),
  ]),
  tuple("Art", [
        MenuEntry("by Ryan Roden-Corrent (rcorre)", null),
        MenuEntry("Creative Commons with Attribution", null),
        MenuEntry("created with Aseprite", null),
  ]),
  tuple("Music", [
        MenuEntry("by Ryan Roden-Corrent (rcorre)", null),
        MenuEntry("Creative Commons with Attribution", null),
        MenuEntry("created with LMMS", null),
  ]),
  tuple("Sound", [
        MenuEntry("by Ryan Roden-Corrent (rcorre)", null),
        MenuEntry("Creative Commons with Attribution", null),
        MenuEntry("with help from Audacity", null),
        MenuEntry("and bxfr", null),
        MenuEntry("and random objects around my apartment", null),
  ]),
  tuple("Font", [
        MenuEntry("Mecha by Captain Falcon", null),
        MenuEntry("Creative Commons Zero (CC0)", null),
        MenuEntry("but hey, nice to give credit anyways :)", null),
  ])
];

/// Show the credits screen.
class ShowCredits : State!(Title, Game) {
  private {
    size_t             _pageNum;
    Font               _titleFont;
    Font               _bodyFont;
    Array!Menu         _menus;
    Array!EventHandler _handlers;
  }

  override {
    void enter(Title title, Game game) {
      _bodyFont  = game.graphics.fonts.get(FontSpec.creditsBody);
      _titleFont = game.graphics.fonts.get(FontSpec.creditsTitle);

      _handlers ~= game.events.onButtonDown("cancel" , &title.popState);
      _handlers ~= game.events.onAxisMoved("move", &moveSelection);

      _menus ~= pageInfo.map!(x => new Menu(x[1]));
      currentMenu.moveTo(centerMenuX);
      currentMenu.setSelection(0);
    }

    void exit(Title title, Game game) {
      foreach(h ; _handlers) h.unregister();
    }

    void run(Title title, Game game) {
      drawTitle(game);

      // draw credits entries
      auto textBatch = TextBatch(_bodyFont, DrawDepth.menuText);
      auto primBatch = PrimitiveBatch(DrawDepth.menuText);

      foreach(menu ; _menus) {
        menu.update(game.deltaTime);
        currentMenu.draw(primBatch, textBatch);
      }

      game.graphics.draw(primBatch);
      game.graphics.draw(textBatch);
    }
  }

  private:
  auto currentMenu() { return _menus[_pageNum]; }

  void moveSelection(Vector2f direction) {
    if (direction.x < 0) {
      currentMenu.moveTo(leftMenuX);
      _pageNum = (_pageNum + pageInfo.length - 1) % pageInfo.length;
      currentMenu.transition(leftMenuX, centerMenuX);
      currentMenu.setSelection(0);
    }
    else if (direction.x > 0) {
      currentMenu.moveTo(leftMenuX);
      _pageNum = (_pageNum + 1) % pageInfo.length;
      currentMenu.transition(rightMenuX, centerMenuX);
      currentMenu.setSelection(0);
    }
    else // vertical selection
      currentMenu.moveSelection(direction);
  }

  private void drawTitle(Game game) {
    auto batch = TextBatch(_titleFont, DrawDepth.menuText);

    Text text;
    text.centered  = true;
    text.color     = Tint.emphasize;
    text.transform = titlePos;
    text.text      = pageInfo[_pageNum][0]; // title of credits page

    batch ~= text;
    game.graphics.draw(batch);
  }
}
