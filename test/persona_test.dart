import 'package:flutter_test/flutter_test.dart';
import 'package:my_pet_cat/game/animations/cat_animations.dart';
import 'package:my_pet_cat/game/cats/cat_persona.dart';
import 'package:my_pet_cat/game/cats/reaction.dart';
import 'package:my_pet_cat/game/environments/environment_id.dart';

const _cats = {
  'Mochi': CatPersonas.mochi,
  'Kitty': CatPersonas.kitty,
  'Biscuit': CatPersonas.biscuit,
  'Luna': CatPersonas.luna,
  'Pepper': CatPersonas.pepper,
  'Snowball': CatPersonas.snowball,
  'Ziggy': CatPersonas.ziggy,
};

const _loves = ReactionOutcome.lovesIt;
const _fine = ReactionOutcome.fine;
const _nope = ReactionOutcome.nope;

void main() {
  group('the same activity, different cats', () {
    // thing id -> expected outcome per cat, in _cats order.
    const table = <String, List<ReactionOutcome>>{
      //               Mochi  Kitty  Biscuit Luna   Pepper Snowball Ziggy
      'bathTime': [_fine, _fine, _nope, _loves, _nope, _loves, _fine],
      'feed': [_fine, _fine, _loves, _fine, _fine, _fine, _fine],
      'climbTree': [_loves, _fine, _nope, _fine, _loves, _nope, _loves],
      'glassTrouble': [_fine, _fine, _loves, _nope, _loves, _nope, _fine],
      'brushFur': [_fine, _loves, _loves, _nope, _fine, _fine, _loves],
      'cardboardBox': [_loves, _loves, _loves, _loves, _loves, _loves, _loves],
      'somethingUnknown': [_fine, _fine, _fine, _fine, _fine, _fine, _fine],
    };

    for (final MapEntry(key: thing, value: expected) in table.entries) {
      test(thing, () {
        final actual = [for (final persona in _cats.values) persona.reactionTo(thing)];
        expect(actual, expected, reason: _cats.keys.join(', '));
      });
    }

    test('overrides beat the trait thresholds', () {
      const fussy = CatPersona(
        tag: 'Test',
        energy: .5,
        curiosity: .5,
        appetite: 1,
        tidiness: .5,
        cuddliness: .5,
        idleHabit: IdleHabit.sniff,
        favourite: EnvironmentId.livingArea,
        tasteOverrides: {'feed': ReactionOutcome.nope},
      );
      expect(fussy.reactionTo('feed'), _nope);
    });
  });

  group('traits drive behaviour numbers', () {
    test('energy scales walk speed between 0.75x and 1.3x', () {
      expect(CatPersonas.biscuit.walkSpeedScale, closeTo(0.86, 0.001));
      expect(CatPersonas.pepper.walkSpeedScale, closeTo(1.245, 0.001));
      for (final p in _cats.values) {
        expect(p.walkSpeedScale, inInclusiveRange(0.75, 1.3));
      }
      expect(CatPersonas.pepper.idlePauseScale, lessThan(CatPersonas.biscuit.idlePauseScale));
      expect(CatPersonas.pepper.zoomiesChance, greaterThan(CatPersonas.biscuit.zoomiesChance));
    });

    test('appetite: Biscuit eats twice as long and begs', () {
      expect(CatPersonas.biscuit.eatScale, 2);
      expect(CatPersonas.kitty.eatScale, 1);
      expect(CatPersonas.biscuit.begsForFood, isTrue);
      expect(CatPersonas.luna.begsForFood, isFalse);
      expect(CatPersonas.biscuit.hungerPerMinute, greaterThan(CatPersonas.luna.hungerPerMinute));
    });

    test('tidiness and cuddliness', () {
      expect(CatPersonas.snowball.dirtPerMinute, lessThan(CatPersonas.pepper.dirtPerMinute));
      expect(CatPersonas.snowball.groomChance, greaterThan(CatPersonas.pepper.groomChance));
      expect(CatPersonas.ziggy.affectionPerPet, greaterThan(CatPersonas.luna.affectionPerPet));
      expect(CatPersonas.ziggy.seeksFinger, isTrue);
      expect(CatPersonas.luna.seeksFinger, isFalse);
      expect(CatPersonas.mochi.inspectChance, greaterThan(CatPersonas.snowball.inspectChance));
    });
  });

  group('reactions are small frame modifiers', () {
    const base = CatFrame(sparkle: 0.1, eyeScale: 1);

    test('loves it: happy eyes and a sparkle', () {
      final f = base.withReaction(_loves);
      expect(f.happyEyes, isTrue);
      expect(f.sparkle, greaterThanOrEqualTo(0.8));
    });

    test('fine: unchanged', () {
      expect(identical(base.withReaction(_fine), base), isTrue);
      expect(identical(base.withReaction(null), base), isTrue);
    });

    test('nope: ears back, surprised, motion marks', () {
      final f = base.withReaction(_nope);
      expect(f.earTwitch, lessThan(0));
      expect(f.eyeScale, greaterThan(1));
      expect(f.mouth, CatMouth.open);
      expect(f.motionMarks, isTrue);
      expect(f.mark, CatMark.exclaim);
    });
  });
}
