module battle.states.victory;

import std.range;
import std.string;
import std.algorithm;

import cid;

import constants;
import battle.battle;
import common.input_hint;
import common.savedata;

private enum {
  titlePos    = Vector2f(screenW * 0.5, screenH * 0.10), // title text position
  totalPos    = Vector2f(screenW * 0.5, screenH * 0.80), // total score position
  scorePos    = Vector2f(screenW * 0.5, screenH * 0.25), // first round score pos
  scoreMargin = Vector2f(0, 60),
  entryDelay  = 0.5f, // time between showing score entries
  musicDelay  = 1.0f, // time after showing total score to start music
}

/// Show the victory screen after a battle is completed.
class BattleVictory : BattleState {
  private {
    AudioStream _music;
    string[]    _scoreEntries;
    string      _titleText;
    string      _totalText;
    Font        _titleFont;
    Font        _entryFont;
    Font        _totalFont;
    SoundBank   _scoreEntrySound;
    SoundEffect _scoreTotalSound;
    int         _showEntries; // show score entries up to this number
    bool        _done;        // true if done displaying scores
    InputHint   _hints;
    SaveData    _saveData;
  }

  this(Battle battle, SaveData saveData) {
    _music          = battle.game.audio.loadStream(MusicPath.victory);
    _music.playmode = AudioPlayMode.loop;
    _music.playing  = false;

    _scoreEntrySound = battle.game.audio.getSoundBank(Sounds.scoreEntry);
    _scoreTotalSound = battle.game.audio.getSound(Sounds.scoreTotal);

    _titleFont = battle.game.graphics.fonts.get(FontSpec.title);
    _entryFont = battle.game.graphics.fonts.get(FontSpec.roundScore);
    _totalFont = battle.game.graphics.fonts.get(FontSpec.totalScore);

    _titleText = "Completed Stage %d-%d".format(battle.worldNum, battle.stageNum);

    _saveData = saveData;
  }

  ~this() {
    _music.destroy();
  }

  override void enter(Battle battle) {
    super.enter(battle);
    battle.stopMusic;

    int totalScore = battle.player.allStats.map!(x => x.totalScore).sum;
    _saveData.recordScore(battle.worldNum, battle.stageNum, totalScore);

    _scoreEntries = battle.player.allStats.enumerate.map!(
      pair => "Round %d: %d".format(pair.index, pair.value.totalScore)).array;

    // display the score for each round one at a time
    foreach(i ; 0 .. _scoreEntries.length) {
      battle.game.events.after(
        entryDelay * (i + 1),
        {
          ++_showEntries;
          _scoreEntrySound.play();
        });
    }

    // after all round scores are shown, show the total score
    battle.game.events.after(
      entryDelay * (battle.player.allStats.length + 1),
      {
        _totalText = "Total: %d".format(totalScore);
        _scoreTotalSound.play();
      });

    // after all score are shown, start playing the victory music
    battle.game.events.after(
      entryDelay * (battle.player.allStats.length + 1) + musicDelay,
      {
        _music.playing = true;
        _done = true;
      });
  }

  override void exit(Battle battle) {
    super.exit(battle);
  }

  override void run(Battle battle) {
    super.run(battle);

    dimBackground(battle.game.graphics);
    drawTitle(battle.game.graphics);
    drawScores(battle.game.graphics);
    drawTotal(battle.game.graphics);

    // draw hint showing button to continue
    if (_done) {
      _hints.update(battle.game.deltaTime);
      _hints.draw(battle.game, InputHint.Action.confirm);
    }
  }

  override void onConfirm(Battle battle) {
    // pop the entire battle state, returning to the main menu
    if (_done) {
      _music.playing = false;
      battle.game.states.pop();
    }
  }

  // disable pause menu in this state
  override void onMenu(Battle battle) { }

  private:
  void dimBackground(Renderer renderer) {
    RectPrimitive prim;

    prim.color  = Tint.dimBackground;
    prim.filled = true;
    prim.rect   = [ 0, 0, screenW, screenH ];

    auto batch = PrimitiveBatch(DrawDepth.overlayBackground);
    batch ~= prim;
    renderer.draw(batch);
  }

  void drawTitle(Renderer renderer) {
    auto batch = TextBatch(_titleFont, DrawDepth.menuText);
    Text text;

    text.text      = _titleText;
    text.color     = Tint.highlight;
    text.centered  = true;
    text.transform = titlePos;

    batch ~= text;
    renderer.draw(batch);
  }

  void drawScores(Renderer renderer) {
    auto batch = TextBatch(_entryFont, DrawDepth.menuText);

    assert(_showEntries <= _scoreEntries.length);

    foreach(i ; 0 .. _showEntries) {
      Text text;

      text.text      = _scoreEntries[i];
      text.color     = Tint.neutral;
      text.centered  = true;
      text.transform = scorePos + scoreMargin * i;

      batch ~= text;
    }

    renderer.draw(batch);
  }

  void drawTotal(Renderer renderer) {
    auto batch = TextBatch(_totalFont, DrawDepth.menuText);
    Text text;

    text.text      = _totalText;
    text.color     = Tint.highlight;
    text.centered  = true;
    text.transform = totalPos;

    batch ~= text;
    renderer.draw(batch);
  }
}
