import '../game/models/activity_definition.dart';
import '../game/models/game_location.dart';

/// The small amount of state the home-screen widget shows. The widget is a
/// presentation and launch surface, not a second game, so this is all it
/// gets: no per-frame animation state.
class PetWidgetPayload {
  const PetWidgetPayload({
    required this.pose,
    required this.location,
    required this.updatedAt,
    this.lastInteraction,
  });

  /// Bump when the stored keys change; native readers ignore newer schemas.
  static const schemaVersion = 1;

  factory PetWidgetPayload.from({
    required GameLocation location,
    CatActivity? completed,
    DateTime? now,
  }) =>
      PetWidgetPayload(
        pose: completed == null ? 'idle' : 'happy',
        location: Locations.of(location).title,
        lastInteraction: completed == null ? null : interactionLabel(completed),
        updatedAt: now ?? DateTime.now(),
      );

  /// Pose name matching the widget frame assets (`widget_kitten_<pose>`).
  final String pose;
  final String location;
  final String? lastInteraction;
  final DateTime updatedAt;

  static String interactionLabel(CatActivity activity) => switch (activity) {
        CatActivity.feed => 'Yum! Thanks for dinner!',
        CatActivity.play => 'That wool was fun!',
        CatActivity.catchMouse => 'The mouse got away!',
        CatActivity.bathTime => 'Squeaky clean!',
        CatActivity.brushFur => 'So soft and fluffy!',
        CatActivity.towelDry => 'All dry and cozy!',
        CatActivity.catchBird => 'The bird waved bye!',
        CatActivity.climbTree => 'I climbed so high!',
        CatActivity.chaseButterflies => 'Butterflies are fast!',
        CatActivity.glassTrouble => 'Oops... who, me?',
        CatActivity.treatTime => 'Found the secret treats!',
        CatActivity.fishySurprise => 'Best fish dinner ever!',
        CatActivity.wardrobeHide => 'Peekaboo! You found me!',
        CatActivity.chewCable => "Zzzap! Cables aren't snacks!",
        CatActivity.pillowJump => 'Best. Pillow. Ever.',
        CatActivity.fishBowl => 'That fish was too quick!',
        CatActivity.purr => 'Purrrr... love you!',
        CatActivity.windowWatch => 'Eek, a bird! ...okay now.',
        CatActivity.duckPond => 'Quack! So loud!',
        CatActivity.leafPile => 'Whee! Leaves everywhere!',
        CatActivity.benchPigeon => 'The pigeon waved bye!',
      };

  Map<String, Object?> toMap() => {
        'schemaVersion': schemaVersion,
        'pose': pose,
        'location': location,
        'lastInteraction': lastInteraction,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };
}
