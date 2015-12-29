/// Move through menus in the title screen
module title.states.credits;

import std.process;

import engine;
import constants;
import common.menu;
import title.title;
import common.input_hint;

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
    InputHint          _hint;
    Array!CreditsPage  _pages;
    Array!EventHandler _handlers;
  }

  override {
    void enter(Title title, Game game) {
      _bodyFont  = game.graphics.fonts.get(FontSpec.creditsBody);
      _titleFont = game.graphics.fonts.get(FontSpec.creditsTitle);

      _handlers ~= game.events.onButtonDown("confirm", { currentPage.confirmSelection(); });
      _handlers ~= game.events.onButtonDown("cancel", &title.popState);
      _handlers ~= game.events.onAxisTapped("move", &moveSelection);

      populatePages(); // assigns to _pages

      currentPage.moveTo(centerMenuX);
      currentPage.activate();
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
        page.update(game.deltaTime);
        //page.menu.draw(primBatch, textBatch);
      }

      currentPage.draw(primBatch, textBatch);

      game.graphics.draw(primBatch);
      game.graphics.draw(textBatch);

      _hint.update(game.deltaTime);
      with (InputHint.Action) {
        if (currentPage.hasUrl)
          _hint.draw(game, up, down, left, right, browse, back);
        else
          _hint.draw(game, up, down, left, right, back);
      }
    }
  }

  private:
  auto currentPage() { return _pages[_pageNum]; }

  void moveSelection(Vector2f direction) {
    if (direction.x < 0) {
      currentPage.moveTo(leftMenuX);
      _pageNum = (_pageNum + _pages.length - 1) % _pages.length;
      currentPage.transition(leftMenuX, centerMenuX);
      currentPage.activate();
    }
    else if (direction.x > 0) {
      currentPage.moveTo(leftMenuX);
      _pageNum = (_pageNum + 1) % _pages.length;
      currentPage.transition(rightMenuX, centerMenuX);
      currentPage.activate();
    }
    else // vertical selection
      currentPage.moveSelection(direction);

    _hint.reset();
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

  private void populatePages() {
    _pages ~= new CreditsPage("Code",
      "by Ryan Roden-Corrent (rcorre)", "https://github.com/rcorre",
      "MIT Licensed", null,
      "written in D", "https://dlang.org",
      "using Allegro5", "https://allegro.cc/",
      "D bindings by SeigeLord", "github.com/SiegeLord/DAllegro5");

    _pages ~= new CreditsPage("Art",
      "by Ryan Roden-Corrent (rcorre)", "https://github.com/rcorre",
      "Creative Commons with Attribution", null,
      "created with Aseprite", "http://aseprite.org");

    _pages ~= new CreditsPage("Music",
      "by Ryan Roden-Corrent (rcorre)", "https://github.com/rcorre",
      "Creative Commons with Attribution", null,
      "created with LMMS", "https://lmms.io");

    _pages ~= new CreditsPage("Sound",
      "by Ryan Roden-Corrent (rcorre)", "https://github.com/rcorre",
      "Creative Commons with Attribution", null,
      "with help from Audacity", "http://www.audacityteam.org/",
      "and bxfr", null);

    _pages ~= new CreditsPage("Other",
      "Font: Mecha by Captain Falcon", "www.fontspace.com/captain-falcon/mecha",
      "Maps created with Tiled", "http://mapeditor.org");
  }
}

private:
class CreditsPage : Menu {
  string title;
  string[] urls;

  this(T...)(string title, T pairs) {
    import std.range, std.array;

    this.title = title;
    this.urls = only(pairs).drop(1).stride(2).array;

    auto entries = only(pairs)
      .chunks(2)
      .map!(x => MenuEntry(x[0], { if (x[1] !is null) browse(x[1]); }));

    super(entries);
  }

  bool hasUrl() { return urls[selectedIndex] !is null; }

  protected override void drawEntry(
      MenuEntry          entry,
      bool               isSelected,
      Vector2i           center,
      ref TextBatch      textBatch,
      ref PrimitiveBatch primBatch)
  {
    Text text;

    // text
    text.centered  = true;
    text.color     = isSelected ? entry.textColor : Tint.subdued;
    text.transform = center;
    text.text      = entry.text;

    textBatch ~= text;

    // draw the url below the selected element
    if (isSelected) {
      text.centered  = true;
      text.color     = Tint.neutral;
      text.text      = urls[selectedIndex];
      text.transform.pos = center + Vector2f(0, 32);
      text.transform.scale = [0.6, 0.6];

      textBatch ~= text;
    }
  }
}
