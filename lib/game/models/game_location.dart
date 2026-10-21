import 'dart:ui';

import 'activity_definition.dart';
import 'game_positions.dart';

enum GameLocation { home, kitchen, bath, outdoors, bedroom }

/// Everything that differs between locations, as data.
class LocationConfig {
  const LocationConfig({
    required this.location,
    required this.title,
    required this.greeting,
    required this.idlePositions,
    required this.walkArea,
    required this.activities,
    this.flourish = const WanderStep.lick(),
  });

  final GameLocation location;
  final String title;

  /// Small handwritten line shown at the top of the screen.
  final String greeting;

  /// Idle spots A, B and C. B is where the cat starts and returns to.
  final List<Offset> idlePositions;

  /// Region (normalized) that idle and start positions must stay inside.
  final Rect walkArea;
  final List<ActivityDefinition> activities;

  /// The little idle habit the kitten shows between walks (e.g. sniffing in
  /// the kitchen).
  final WanderStep flourish;

  Offset get startPosition => idlePositions[1];
  Offset get returnPosition => idlePositions[1];

  /// Deterministic idle routine; starts and restarts at [startPosition].
  List<WanderStep> get wanderRoutine => [
        const WanderStep.pause(2.2),
        const WanderStep.lick(),
        WanderStep.walk(idlePositions[0]),
        const WanderStep.pause(1.8),
        WanderStep.walk(idlePositions[1]),
        const WanderStep.pause(1.4),
        WanderStep.walk(idlePositions[2]),
        const WanderStep.pause(2.0),
        flourish,
        WanderStep.walk(idlePositions[1]),
      ];
}

abstract final class Locations {
  static const home = LocationConfig(
    location: GameLocation.home,
    title: 'Home',
    greeting: 'Hello, Kitty!',
    idlePositions: [
      HomePositions.idlePositionA,
      HomePositions.idlePositionB,
      HomePositions.idlePositionC,
    ],
    walkArea: Rect.fromLTRB(0.3, 0.70, 0.7, 0.78),
    activities: [
      ActivityDefinition(CatActivity.feed, 'Feed', 'Feed the cat'),
      ActivityDefinition(CatActivity.play, 'Play', 'Play with the cat'),
      ActivityDefinition(CatActivity.catchMouse, 'Catch Mice', 'Catch mice'),
    ],
  );

  static const kitchen = LocationConfig(
    location: GameLocation.kitchen,
    title: 'Kitchen',
    greeting: "What's cooking, Kitty?",
    idlePositions: [
      KitchenPositions.idlePositionA,
      KitchenPositions.idlePositionB,
      KitchenPositions.idlePositionC,
    ],
    walkArea: Rect.fromLTRB(0.28, 0.70, 0.62, 0.78),
    flourish: WanderStep.sniff(1.6),
    activities: [
      ActivityDefinition(CatActivity.glassTrouble, 'Glass', 'Glass trouble', accent: 0xFFE4ECFB),
      ActivityDefinition(CatActivity.treatTime, 'Treat', 'Treat time', accent: 0xFFFBD9D2),
      ActivityDefinition(CatActivity.fishySurprise, 'Fish', 'Fishy surprise', accent: 0xFFFDE6C8),
    ],
  );

  static const bath = LocationConfig(
    location: GameLocation.bath,
    title: 'Bath',
    greeting: 'Splish, splash!',
    idlePositions: [
      BathPositions.idlePositionA,
      BathPositions.idlePositionB,
      BathPositions.idlePositionC,
    ],
    walkArea: Rect.fromLTRB(0.48, 0.70, 0.82, 0.78),
    activities: [
      ActivityDefinition(CatActivity.bathTime, 'Bath Time', 'Bath time'),
      ActivityDefinition(CatActivity.brushFur, 'Brush Fur', 'Brush fur'),
      ActivityDefinition(CatActivity.towelDry, 'Towel Dry', 'Towel dry'),
    ],
  );

  static const outdoors = LocationConfig(
    location: GameLocation.outdoors,
    title: 'Outdoors',
    greeting: "Let's explore!",
    idlePositions: [
      OutdoorPositions.idlePositionA,
      OutdoorPositions.idlePositionB,
      OutdoorPositions.idlePositionC,
    ],
    walkArea: Rect.fromLTRB(0.4, 0.70, 0.74, 0.78),
    activities: [
      ActivityDefinition(CatActivity.catchBird, 'Catch Bird', 'Catch bird'),
      ActivityDefinition(CatActivity.climbTree, 'Climb Tree', 'Climb tree'),
      ActivityDefinition(CatActivity.chaseButterflies, 'Chase Butterflies', 'Chase butterflies'),
    ],
  );

  static const bedroom = LocationConfig(
    location: GameLocation.bedroom,
    title: 'Bedroom',
    greeting: 'Shh... it\'s her room!',
    idlePositions: [
      BedroomPositions.idlePositionA,
      BedroomPositions.idlePositionB,
      BedroomPositions.idlePositionC,
    ],
    walkArea: Rect.fromLTRB(0.28, 0.70, 0.66, 0.78),
    activities: [
      ActivityDefinition(CatActivity.wardrobeHide, 'Wardrobe', 'Hide in the wardrobe', accent: 0xFFF3DDBF),
      ActivityDefinition(CatActivity.chewCable, 'Cable', 'Chew the cable', accent: 0xFFFFF1B8),
      ActivityDefinition(CatActivity.pillowJump, 'Pillow', 'Jump on the pillow', accent: 0xFFFBD9E6),
    ],
  );

  static LocationConfig of(GameLocation location) => switch (location) {
        GameLocation.home => home,
        GameLocation.kitchen => kitchen,
        GameLocation.bath => bath,
        GameLocation.outdoors => outdoors,
        GameLocation.bedroom => bedroom,
      };
}
