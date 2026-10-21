import '../environments/environment_id.dart';
import '../models/cat_look.dart';
import '../progression/unlock_thresholds.dart';
import 'cat_persona.dart';

/// The seven adoptable cats. Saved by [name], so never rename.
enum CatId {
  mochi,
  kitty,
  biscuit,
  luna,
  pepper,
  snowball,
  ziggy;

  static CatId? tryParse(Object? name) {
    for (final id in values) {
      if (id.name == name) return id;
    }
    return null;
  }
}

/// One adoptable cat: how she looks (a painter) plus who she is (data).
class CatProfile {
  const CatProfile({
    required this.id,
    required this.name,
    required this.look,
    required this.persona,
    required this.greetings,
  });

  final CatId id;
  final String name;
  final CatLook look;
  final CatPersona persona;

  /// Handwritten header lines, picked one at a time.
  final List<String> greetings;

  EnvironmentId get favouriteEnvironment => persona.favourite;
  UnlockRule get unlockRule => UnlockThresholds.cat(id);
}

/// Every cat that can be drawn so far, in carousel order. Snowball and
/// Ziggy join as their looks are painted.
abstract final class CatProfiles {
  static const mochi = CatProfile(
    id: CatId.mochi,
    name: 'Mochi',
    look: CatLook.fluffy,
    persona: CatPersonas.mochi,
    greetings: [
      'Ooh, what is that?',
      'Sniff sniff... new smells!',
      "Let's explore!",
      'Mrrp? What are we doing?',
      'Everything is so interesting!',
      'Can I see? Can I see?',
      'Adventure time!',
      'Hello, explorer!',
    ],
  );

  static const kitty = CatProfile(
    id: CatId.kitty,
    name: 'Kitty',
    look: CatLook.classic,
    persona: CatPersonas.kitty,
    greetings: [
      'Hello, friend!',
      'Purr... happy to see you.',
      'Nice day, isn\'t it?',
      'Slow blink. That means I love you.',
      'Shall we play?',
      'I saved you a spot.',
      'Mew!',
      'You came back!',
    ],
  );

  static const biscuit = CatProfile(
    id: CatId.biscuit,
    name: 'Biscuit',
    look: CatLook.ginger,
    persona: CatPersonas.biscuit,
    greetings: [
      'Is it snack o\'clock?',
      'Yawn... hello there.',
      'I smell treats. Do you smell treats?',
      'Nap first, then food. Or food first.',
      'Purrrr. Belly rubs accepted.',
      'Is that a fish? Please say fish.',
      'Five more minutes...',
      'You look like someone with snacks.',
    ],
  );

  static const luna = CatProfile(
    id: CatId.luna,
    name: 'Luna',
    look: CatLook.tuxedo,
    persona: CatPersonas.luna,
    greetings: [
      '...oh, it\'s you. Hi.',
      'Is it quiet here? Good.',
      'I like the stars best.',
      '*peeks* ...hello.',
      'You can stay. I suppose.',
      'Shh. I\'m listening to the night.',
      'Slow blink... (that means hi).',
      'Too bright. Is it evening yet?',
    ],
  );

  static const pepper = CatProfile(
    id: CatId.pepper,
    name: 'Pepper',
    look: CatLook.tortie,
    persona: CatPersonas.pepper,
    greetings: [
      'Zoom zoom zoom!',
      'What happens if I push this?',
      'It wasn\'t me. Probably.',
      'Catch me if you can!',
      'Everything is a toy!',
      'Oops! Ha, again!',
      'Let\'s make some mischief!',
      'Who left this on the table?',
    ],
  );

  static const all = [mochi, kitty, biscuit, luna, pepper];

  static CatProfile? byId(CatId id) {
    for (final cat in all) {
      if (cat.id == id) return cat;
    }
    return null;
  }

  static CatProfile forLook(CatLook look) => all.firstWhere((cat) => cat.look == look);
}
