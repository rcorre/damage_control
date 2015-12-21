/// Move through menus in the title screen
module title.states.credits;

import std.process;
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

/// Show the credits screen.
class ShowCredits : State!(Title, Game) {
  private {
    size_t             _pageNum;
    Font               _titleFont;
    Font               _bodyFont;
    Array!CreditsPage  _pages;
    Array!EventHandler _handlers;
  }

  override {
    void enter(Title title, Game game) {
      _bodyFont  = game.graphics.fonts.get(FontSpec.creditsBody);
      _titleFont = game.graphics.fonts.get(FontSpec.creditsTitle);

      _handlers ~= game.events.onButtonDown("confirm", { currentMenu.confirmSelection(); });
      _handlers ~= game.events.onButtonDown("cancel", &title.popState);
      _handlers ~= game.events.onAxisMoved("move", &moveSelection);

      populatePages(); // assigns to _pages

      currentMenu.moveTo(centerMenuX);
      currentMenu.activate();
    }

    void exit(Title title, Game game) {
      foreach(h ; _handlers) h.unregister();
    }

    void run(Title title, Game game) {
      drawTitle(game);

      // draw credits entries
      auto textBatch = TextBatch(_bodyFont, DrawDepth.menuText);
      auto primBatch = PrimitiveBatch(DrawDepth.menuText);

      foreach(page ; _pages) {
        page.menu.update(game.deltaTime);
        //page.menu.draw(primBatch, textBatch);
      }

      currentMenu.draw(primBatch, textBatch);

      game.graphics.draw(primBatch);
      game.graphics.draw(textBatch);
    }
  }

  private:
  auto currentPage() { return _pages[_pageNum]; }
  auto currentMenu() { return currentPage.menu; }

  void moveSelection(Vector2f direction) {
    if (direction.x < 0) {
      currentMenu.moveTo(leftMenuX);
      _pageNum = (_pageNum + _pages.length - 1) % _pages.length;
      currentMenu.transition(leftMenuX, centerMenuX);
      currentMenu.activate();
    }
    else if (direction.x > 0) {
      currentMenu.moveTo(leftMenuX);
      _pageNum = (_pageNum + 1) % _pages.length;
      currentMenu.transition(rightMenuX, centerMenuX);
      currentMenu.activate();
    }
    else // vertical selection
      currentMenu.moveSelection(direction);
  }

  void drawTitle(Game game) {
    auto batch = TextBatch(_titleFont, DrawDepth.menuText);

    Text text;
    text.centered  = true;
    text.color     = Tint.emphasize;
    text.transform = titlePos;
    text.text      = _pages[_pageNum].title;

    batch ~= text;
    game.graphics.draw(batch);
  }

  struct CreditsPage { string title; Menu menu; }

  private void populatePages() {
    _pages ~= CreditsPage("Code",
        new Menu(
          MenuEntry("by Ryan Roden-Corrent (rcorre)", { browse("https://github.com/rcorre"); }),
          MenuEntry("MIT Licensed", { }),
          MenuEntry("written in D", { browse("https://dlang.org"); }),
          MenuEntry("using Allegro5", { browse("https://allegro.cc/"); }),
          MenuEntry("D bindings by SeigeLord", { })));

    _pages ~= CreditsPage("Art",
        new Menu(
          MenuEntry("by Ryan Roden-Corrent (rcorre)", { }),
          MenuEntry("Creative Commons with Attribution", { }),
          MenuEntry("created with Aseprite", { browse("http://aseprite.org"); })));

    _pages ~= CreditsPage("Music",
        new Menu(
          MenuEntry("by Ryan Roden-Corrent (rcorre)", { }),
          MenuEntry("Creative Commons with Attribution", { }),
          MenuEntry("created with LMMS", { browse("https://lmms.io"); })));

    _pages ~= CreditsPage("Sound",
        new Menu(
          MenuEntry("by Ryan Roden-Corrent (rcorre)", { }),
          MenuEntry("Creative Commons with Attribution", { }),
          MenuEntry("with help from Audacity", { }),
          MenuEntry("and bxfr", { }),
          MenuEntry("and random objects around my apartment", { })));

    _pages ~= CreditsPage("Other",
        new Menu(
          MenuEntry("Font: Mecha by Captain Falcon", { }),
          MenuEntry("Maps created with Tiled", { browse("http://mapeditor.org"); })));
  }
}
