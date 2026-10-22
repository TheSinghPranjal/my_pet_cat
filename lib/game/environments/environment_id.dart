import '../models/game_location.dart';

/// The seven places of My Pet Cat 2.0. Saved by [name], so never rename.
enum EnvironmentId {
  /// The 1.x Home.
  livingArea,
  kitchen,
  bathroom,
  bedroom,
  park,
  rooftop,
  car,

  /// The 1.x Outdoors garden.
  garden,
  livingRoom;

  /// The 1.x scene that becomes this place, until every place has its own
  /// environment config.
  static EnvironmentId fromLocation(GameLocation location) => switch (location) {
    GameLocation.home => livingArea,
    GameLocation.kitchen => kitchen,
    GameLocation.bath => bathroom,
    GameLocation.outdoors => garden,
    GameLocation.bedroom => bedroom,
    GameLocation.livingRoom => livingRoom,
    GameLocation.park => park,
  };

  static EnvironmentId? tryParse(Object? name) {
    for (final id in values) {
      if (id.name == name) return id;
    }
    return null;
  }
}
