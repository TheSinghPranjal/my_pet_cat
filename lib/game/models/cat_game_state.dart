import 'dart:ui';

/// What the game is doing at the highest level. Activities and location
/// changes are only accepted while [idle].
enum GameMode { idle, busy, changingLocation }

/// The gameplay state, with a finer label for the step a script is on.
///
/// Scripts set these with `Phase` steps. New activities only use [busy];
/// the other busy values label the steps of the 1.x activities.
enum CatGameState {
  idle,
  busy,
  walkingToFood,
  eating,
  returningFromFood,
  walkingToToy,
  playing,
  returningFromPlay,
  catchingMouse,
  walkingToBath,
  bathing,
  brushing,
  drying,
  catchingBird,
  climbingTree,
  chasingButterflies,
  glassTrouble,
  glassClimbing,
  glassInvestigating,
  glassFalling,
  glassReaction,
  treatTime,
  treatScratching,
  treatRevealing,
  treatEating,
  fishySurprise,
  fishSniffing,
  fishCooking,
  fishServing,
  fishEating,
  returningToIdle,
  changingLocation;

  GameMode get mode => switch (this) {
    idle => GameMode.idle,
    changingLocation => GameMode.changingLocation,
    _ => GameMode.busy,
  };
}

/// Which animation set the kitten is currently showing.
enum CatPose {
  idle,
  walk,
  lick,
  eat,
  play,
  happy,
  crouch,
  pounce,
  surprised,
  sit,
  relax,
  shake,
  climb,
  lookUp,
  swat,
  scratch,
  sniff,
  satisfied,
  innocent,
  lookDown,
}

enum ObjectKind { bowl, yarn, mouse, bird, butterfly, brush, towel, glass, treat, fish, plate }

/// A temporary prop or critter in the scene.
///
/// Positions are normalized (0..1) and anchored at the bottom-center of the
/// sprite. [appear] and [pop] are 0..1 progress values for the spawn and
/// disappear animations.
class SpawnedObject {
  SpawnedObject(this.kind, this.position, {this.facing = 1});

  final ObjectKind kind;
  Offset position;
  double appear = 0;
  double pop = 0;
  double rotation = 0;

  /// 1 = facing right, -1 = facing left.
  double facing;

  /// How much food is left (bowl, treat, served plate).
  double fill = 1;

  /// Generic 0..1 progress, e.g. how cooked the fish is.
  double progress = 0;

  /// Seconds since spawn; drives idle loops like sniffing or flapping.
  double phase = 0;

  /// True while the object is travelling (scurrying legs, hopping).
  bool moving = false;

  /// True for things in the air (flapping wings).
  bool airborne = false;

  /// Added to the y used for draw order, so e.g. a towel stays in front of
  /// the cat it covers.
  double layerBias = 0;

  double get sortY => position.dy + layerBias;
}

enum EffectKind { bubbles, splash, sparkles, droplets, leaves, puff, aroma, steam, heat, scratches, impact, hearts, timer }

/// A lightweight sketch effect anchored at a normalized position. Its look is
/// a pure function of [time], so it needs no per-particle state.
class SceneEffect {
  SceneEffect(this.kind, this.anchor, {this.duration});

  final EffectKind kind;
  final Offset anchor;

  /// When set, the effect removes itself after this many seconds.
  final double? duration;
  double time = 0;
  double fade = 1;
}
