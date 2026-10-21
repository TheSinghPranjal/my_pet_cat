import '../animations/cat_animations.dart';

/// How a cat feels about how an activity turned out.
enum ReactionOutcome { lovesIt, fine, nope }

/// The personality traits, each 0..1.
enum Trait { energy, curiosity, appetite, tidiness, cuddliness }

/// Which trait decides how much a cat enjoys one thing.
///
/// A cat scoring at least [lovesAt] on the trait loves it, at most [nopeAt]
/// says nope, and anything between is fine. [inverted] flips the trait
/// (e.g. messy cats love knocking things over).
class ThingTaste {
  const ThingTaste(this.trait, {this.inverted = false, this.lovesAt = 0.7, this.nopeAt = 0.3});

  /// Everyone loves it, whatever their traits (the cardboard box).
  const ThingTaste.universal() : trait = null, inverted = false, lovesAt = 0, nopeAt = -1;

  final Trait? trait;
  final bool inverted;
  final double lovesAt;
  final double nopeAt;

  ReactionOutcome outcomeFor(double Function(Trait) traits) {
    final t = trait;
    if (t == null) return ReactionOutcome.lovesIt;
    // Both thresholds are inclusive; the epsilon keeps 1 - 0.7 on the line.
    const epsilon = 1e-9;
    final score = inverted ? 1 - traits(t) : traits(t);
    if (score >= lovesAt - epsilon) return ReactionOutcome.lovesIt;
    if (score <= nopeAt + epsilon) return ReactionOutcome.nope;
    return ReactionOutcome.fine;
  }
}

/// The three reaction variants as small changes to any [CatFrame], so every
/// pose of every cat can react without new animation code.
extension CatReactionFrame on CatFrame {
  CatFrame withReaction(ReactionOutcome? outcome) => switch (outcome) {
    null || ReactionOutcome.fine => this,
    ReactionOutcome.lovesIt => copyWith(happyEyes: true, sparkle: sparkle < 0.8 ? 0.8 : sparkle),
    ReactionOutcome.nope => copyWith(
      earTwitch: -0.45,
      eyeScale: eyeScale * 1.15,
      happyEyes: false,
      mouth: CatMouth.open,
      motionMarks: true,
      mark: mark == CatMark.none ? CatMark.exclaim : mark,
    ),
  };
}
