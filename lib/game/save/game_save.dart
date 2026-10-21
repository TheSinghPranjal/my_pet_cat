import '../cats/cat_needs.dart';
import '../cats/cat_profile.dart';
import '../environments/environment_id.dart';
import '../progression/unlock_thresholds.dart';

/// Player settings.
class GameSettings {
  GameSettings({this.wander = true, this.sound = false});

  /// "Let kitty wander around".
  bool wander;

  /// Optional sound effects; off by default.
  bool sound;

  Map<String, Object?> toJson() => {'wander': wander, 'sound': sound};

  factory GameSettings.fromJson(Object? json) {
    final map = json is Map ? json : const {};
    return GameSettings(
      wander: map['wander'] is bool ? map['wander'] as bool : true,
      sound: map['sound'] is bool ? map['sound'] as bool : false,
    );
  }
}

/// Progress with one cat.
class CatSave {
  CatSave({this.needs = CatNeeds.initial, this.friendship = 0, Set<String>? completed}) : completed = completed ?? {};

  static const maxStars = 5.0;

  CatNeeds needs;

  /// Friendship in stars, 0..5; whole stars count toward unlocks.
  double friendship;

  /// Thing ids this cat has done at least once.
  final Set<String> completed;

  int get stars => friendship.floor();

  Map<String, Object?> toJson() => {
    'needs': needs.toJson(),
    'friendship': friendship,
    'completed': completed.toList()..sort(),
  };

  factory CatSave.fromJson(Object? json) {
    final map = json is Map ? json : const {};
    final friendship = map['friendship'];
    return CatSave(
      needs: CatNeeds.fromJson(map['needs']),
      friendship: friendship is num && friendship.isFinite ? friendship.toDouble().clamp(0, maxStars) : 0,
      completed: _strings(map['completed']),
    );
  }
}

/// Everything the game remembers, stored as one JSON blob.
///
/// Parsing is forgiving: anything missing, unknown or of the wrong type
/// falls back to its default, so a damaged save never stops the game.
class GameSave {
  GameSave({
    this.selectedCat = CatId.mochi,
    this.lastEnvironment = EnvironmentId.livingArea,
    GameSettings? settings,
    Map<CatId, CatSave>? cats,
    Set<String>? stickers,
    Set<String>? unlocked,
    this.lastSeen,
  }) : settings = settings ?? GameSettings(),
       cats = cats ?? {},
       stickers = stickers ?? {},
       unlocked = unlocked ?? {};

  /// Bump when the JSON layout changes, and add a step to [migrate].
  static const schemaVersion = 1;

  CatId selectedCat;
  EnvironmentId lastEnvironment;
  final GameSettings settings;
  final Map<CatId, CatSave> cats;

  /// Thing ids whose sticker is in the sticker book.
  final Set<String> stickers;

  /// Ids ("cat:luna", "env:park") whose unlock page has been shown.
  final Set<String> unlocked;

  /// When the game was last open, for the capped offline drift of needs.
  DateTime? lastSeen;

  CatSave cat(CatId id) => cats.putIfAbsent(id, CatSave.new);

  int get totalStars => cats.values.fold(0, (sum, c) => sum + c.stars);

  bool isCatUnlocked(CatId id) => UnlockThresholds.cat(id).isMet(totalStars);

  bool isEnvironmentUnlocked(EnvironmentId id) => UnlockThresholds.environment(id).isMet(totalStars);

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'selectedCat': selectedCat.name,
    'lastEnvironment': lastEnvironment.name,
    'settings': settings.toJson(),
    'cats': {for (final MapEntry(:key, :value) in cats.entries) key.name: value.toJson()},
    'stickers': stickers.toList()..sort(),
    'unlocked': unlocked.toList()..sort(),
    'lastSeen': lastSeen?.millisecondsSinceEpoch,
  };

  factory GameSave.fromJson(Object? raw) {
    final json = migrate(raw is Map ? Map<String, Object?>.from(raw) : {});
    final cats = <CatId, CatSave>{};
    if (json['cats'] case final Map map) {
      for (final MapEntry(:key, :value) in map.entries) {
        final id = CatId.tryParse(key);
        if (id != null) cats[id] = CatSave.fromJson(value);
      }
    }
    final lastSeen = json['lastSeen'];
    return GameSave(
      selectedCat: _unlockedOrDefault(CatId.tryParse(json['selectedCat']), cats),
      lastEnvironment: EnvironmentId.tryParse(json['lastEnvironment']) ?? EnvironmentId.livingArea,
      settings: GameSettings.fromJson(json['settings']),
      cats: cats,
      stickers: _strings(json['stickers']),
      unlocked: _strings(json['unlocked']),
      lastSeen: lastSeen is int ? DateTime.fromMillisecondsSinceEpoch(lastSeen) : null,
    );
  }

  /// Upgrades older layouts step by step to [schemaVersion]. Saves from a
  /// newer app are read as-is, keeping whatever this version understands.
  static Map<String, Object?> migrate(Map<String, Object?> json) {
    var version = json['schemaVersion'] is int ? json['schemaVersion'] as int : 0;
    if (version < 1) {
      // v0: nothing was saved but the look; the 1.x key is migrated by the
      // store before parsing, so there is nothing to move here.
      version = 1;
    }
    return json..['schemaVersion'] = version;
  }

  /// A locked cat can never be the selected one.
  static CatId _unlockedOrDefault(CatId? id, Map<CatId, CatSave> cats) {
    if (id == null) return CatId.mochi;
    final stars = cats.values.fold(0, (sum, c) => sum + c.stars);
    return UnlockThresholds.cat(id).isMet(stars) ? id : CatId.mochi;
  }
}

Set<String> _strings(Object? json) => json is List ? json.whereType<String>().toSet() : <String>{};
