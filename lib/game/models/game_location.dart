import 'dart:ui';

import 'activity_definition.dart';
import 'game_positions.dart';

enum GameLocation { home, bath, outdoors }

/// Everything that differs between locations, as data.
class LocationConfig {
  const LocationConfig({
    required this.location,
    required this.title,
    required this.greeting,
    required this.idlePositions,
    required this.walkArea,
    required this.activities,
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
        const WanderStep.lick(),
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

  static LocationConfig of(GameLocation location) => switch (location) {
        GameLocation.home => home,
        GameLocation.bath => bath,
        GameLocation.outdoors => outdoors,
      };
}
