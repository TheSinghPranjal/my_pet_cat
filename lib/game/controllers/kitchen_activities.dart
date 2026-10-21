part of 'cat_game_controller.dart';

extension _KitchenActivities on CatGameController {
  /// Shows [mark] over the kitten for [seconds], then clears it.
  Future<bool> _flashMark(CatMark mark, double seconds) async {
    _mark = mark;
    final ok = await _wait(seconds);
    if (ok) _mark = CatMark.none;
    return ok;
  }

  Future<bool> _glassTroubleSequence() async {
    const p = KitchenPositions.glassSpawnPosition;
    final glass = _spawn(ObjectKind.glass, p);

    // A. Notice the counter, trot over and look up.
    if (!await _turnToward(KitchenPositions.glassCounterApproachPosition)) return false;
    _setPose(CatPose.lookUp);
    if (!await _flashMark(CatMark.exclaim, 0.7)) return false;
    if (!await _walkTo(KitchenPositions.glassCounterApproachPosition, endFacing: -1, endPose: CatPose.lookUp)) {
      return false;
    }
    if (!await _wait(0.5)) return false;

    // B. Up the cabinet front and onto the counter.
    _setState(CatGameState.glassClimbing);
    _setPose(CatPose.climb);
    if (!await _moveCat(KitchenPositions.glassClimbPositionA, 0.6)) return false;
    if (!await _moveCat(KitchenPositions.glassClimbPositionB, 0.6)) return false;
    if (!await _turnTo(1)) return false;
    if (!await _pounce(KitchenPositions.glassCounterIdlePosition, height: 6, duration: const Duration(milliseconds: 400))) {
      return false;
    }
    _setPose(CatPose.idle);

    // C. A glass! Look, lean in, tap it twice.
    _setState(CatGameState.glassInvestigating);
    _focus = glass;
    if (!await _appear(glass)) return false;
    _setPose(CatPose.sniff);
    if (!await _wait(0.8)) return false;
    _setPose(CatPose.swat);
    if (!await _all([
      _swipePaw(),
      _after(0.2, () => _animate(_sec(GameTimings.glassTap), (t) => glass.rotation = math.sin(t * math.pi) * 0.25)),
    ])) {
      return false;
    }
    if (!await _all([
      _swipePaw(),
      _after(0.2, () => _moveObject(glass, KitchenPositions.glassEdgePosition, _sec(GameTimings.glassTap),
          faceMovement: false)),
      _after(0.2, () => _animate(_sec(GameTimings.glassTap), (t) => glass.rotation = 0.35 * t)),
    ])) {
      return false;
    }

    // D. Over the edge along a fixed path, a soft bonk, and a puff.
    _setState(CatGameState.glassFalling);
    _setPose(CatPose.lookDown);
    final fall = _sec(GameTimings.glassFall);
    if (!await _moveObject(glass, KitchenPositions.glassFallWaypointA, fall * 0.25, faceMovement: false)) return false;
    if (!await _all([
      _moveObject(glass, KitchenPositions.glassFallWaypointB, fall * 0.35, curve: Curves.easeIn, faceMovement: false),
      _animate(fall * 0.35, (t) => glass.rotation = 0.35 + 1.2 * t),
    ])) {
      return false;
    }
    if (!await _all([
      _moveObject(glass, KitchenPositions.glassLandingPosition, fall * 0.4, curve: Curves.easeIn, faceMovement: false),
      _animate(fall * 0.4, (t) => glass.rotation = 1.55 + 0.05 * t),
    ])) {
      return false;
    }
    _addEffect(EffectKind.impact, KitchenPositions.glassLandingPosition, duration: 0.6);
    _setState(CatGameState.glassReaction);
    _setPose(CatPose.surprised);
    // A harmless little bounce, then it vanishes in a puff (no shards).
    if (!await _moveObject(glass, KitchenPositions.glassLandingPosition, 0.3, arc: 0.02, faceMovement: false)) {
      return false;
    }
    _puff(KitchenPositions.glassLandingPosition);
    if (!await _popAway(glass)) return false;
    _setPose(CatPose.lookDown);
    if (!await _wait(0.6)) return false;

    // E. Who, me?
    _setPose(CatPose.innocent);
    if (!await _wait(1.6)) return false;
    _setState(CatGameState.returningToIdle);
    if (!await _turnTo(-1)) return false;
    if (!await _pounce(KitchenPositions.glassHopDownPosition, height: 14)) return false;
    _setPose(CatPose.idle);
    return _walkTo(KitchenPositions.glassCatReturnPosition);
  }

  Future<bool> _treatTimeSequence() async {
    // A. Sniff out the right cabinet.
    if (!await _walkTo(KitchenPositions.treatCabinetApproachPosition, endFacing: -1, endPose: CatPose.sniff)) {
      return false;
    }
    _addEffect(EffectKind.aroma, KitchenPositions.treatCabinetDoorPosition + const Offset(0.05, -0.07),
        duration: _sec(GameTimings.sniff));
    if (!await _wait(_sec(GameTimings.sniff))) return false;
    _setPose(CatPose.idle);
    if (!await _flashMark(CatMark.exclaim, 0.5)) return false;

    // B. Scratch, sniff, scratch; the cabinet rattles a little.
    _setState(CatGameState.treatScratching);
    if (!await _walkTo(KitchenPositions.treatScratchPosition, endFacing: -1)) return false;
    final scratchMarks = KitchenPositions.treatCabinetDoorPosition + const Offset(0.02, -0.07);
    for (var i = 0; i < GameTimings.scratchBursts; i++) {
      _setPose(CatPose.scratch);
      final marks = _addEffect(EffectKind.scratches, scratchMarks);
      final ok = await _animate(_sec(GameTimings.scratchBurst),
          (t) => _cabinetOpen = math.sin(t * math.pi * 6).abs() * 0.04);
      _effects.remove(marks);
      if (!ok) return false;
      if (i < GameTimings.scratchBursts - 1) {
        _setPose(CatPose.sniff);
        if (!await _wait(0.5)) return false;
      }
    }

    // C. The door creaks open and a treat pops out.
    _setState(CatGameState.treatRevealing);
    _setPose(CatPose.idle);
    if (!await _animate(_sec(GameTimings.cabinetDoor), (t) => _cabinetOpen = Curves.easeOut.transform(t))) {
      return false;
    }
    final treat = _spawn(ObjectKind.treat, KitchenPositions.treatSpawnPosition, layerBias: 0.02);
    _focus = treat;
    if (!await _appear(treat)) return false;
    if (!await _moveObject(treat, KitchenPositions.treatRevealPosition, 0.5, arc: 0.03, faceMovement: false)) {
      return false;
    }
    _addEffect(EffectKind.sparkles, KitchenPositions.treatRevealPosition + const Offset(0, -0.02));
    _setPose(CatPose.surprised);
    _addEffect(EffectKind.hearts, _catPosition + const Offset(0.02, -0.13), duration: 1.0);
    if (!await _wait(0.8)) return false;

    // D. Nom.
    _setState(CatGameState.treatEating);
    if (!await _all([
      _walkTo(KitchenPositions.treatEatingPosition, endFacing: -1),
      _moveObject(treat, KitchenPositions.treatServePosition, 0.5, faceMovement: false),
    ])) {
      return false;
    }
    _setPose(CatPose.eat);
    if (!await _animate(_sec(GameTimings.treatEating), (t) => treat.fill = 1 - t)) return false;
    _remove(treat);
    _effects.clear();
    _setPose(CatPose.satisfied);
    _addEffect(EffectKind.hearts, _catPosition + const Offset(0, -0.13), duration: _sec(GameTimings.satisfied));
    if (!await _wait(_sec(GameTimings.satisfied))) return false;

    // E. Close up and head back.
    _setState(CatGameState.returningToIdle);
    if (!await _animate(_sec(GameTimings.cabinetDoor), (t) => _cabinetOpen = 1 - t)) return false;
    return _walkTo(KitchenPositions.treatCatReturnPosition);
  }

  Future<bool> _fishySurpriseSequence() async {
    // A. Something smells good...
    _setState(CatGameState.fishSniffing);
    if (!await _walkTo(KitchenPositions.fishCatStartPosition)) return false;
    final aroma = _addEffect(EffectKind.aroma, KitchenPositions.fishAromaPosition);
    _setPose(CatPose.sniff);
    if (!await _wait(_sec(GameTimings.sniff))) return false;
    if (!await _turnToward(KitchenPositions.fishPanPosition)) return false;
    _setPose(CatPose.lookUp);
    if (!await _flashMark(CatMark.exclaim, 0.6)) return false;
    if (!await _walkTo(KitchenPositions.fishCatSniffPosition, endFacing: 1, endPose: CatPose.sniff)) return false;
    if (!await _wait(_sec(GameTimings.sniff))) return false;

    // B. Into the pan; watch from a safe spot.
    final fish = _spawn(ObjectKind.fish, KitchenPositions.fishRawSpawnPosition);
    _focus = fish;
    if (!await _all([
      _appear(fish),
      _walkTo(KitchenPositions.fishCatWatchPosition, endFacing: 1, endPose: CatPose.sit),
    ])) {
      return false;
    }
    if (!await _moveObject(fish, KitchenPositions.fishCookingPosition, 0.5, curve: Curves.easeIn, faceMovement: false)) {
      return false;
    }

    // C. Sizzle: steam, heat marks, a little timer; raw turns golden.
    _setState(CatGameState.fishCooking);
    _effects.remove(aroma);
    final steam = _addEffect(EffectKind.steam, KitchenPositions.fishAromaPosition);
    final heat = _addEffect(EffectKind.heat, KitchenPositions.fishPanPosition);
    final cook = _sec(GameTimings.fishCooking);
    final timer = _addEffect(EffectKind.timer, KitchenPositions.fishTimerPosition, duration: cook + 0.3);
    if (!await _animate(cook, (t) => fish.progress = t)) return false;
    _effects.removeWhere((e) => e == heat || e == timer);
    _addEffect(EffectKind.sparkles, KitchenPositions.fishCookingPosition + const Offset(0, -0.03));
    _setPose(CatPose.happy);
    if (!await _wait(0.6)) return false;

    // D. Onto a plate, and the plate onto the floor, away from the stove.
    _setState(CatGameState.fishServing);
    final plate = _spawn(ObjectKind.plate, KitchenPositions.fishServingSpawnPosition)..fill = 0;
    if (!await _appear(plate)) return false;
    if (!await _moveObject(fish, KitchenPositions.fishServingSpawnPosition, 0.6, arc: 0.06, faceMovement: false)) {
      return false;
    }
    _remove(fish);
    plate.fill = 1; // The cooked fish now rides on the plate.
    _effects.remove(steam);
    _effects.removeWhere((e) => e.kind == EffectKind.sparkles);
    _focus = plate;
    if (!await _moveObject(plate, KitchenPositions.fishServingMoveWaypoint, 0.45, faceMovement: false)) return false;
    if (!await _moveObject(plate, KitchenPositions.fishServingPosition, 0.45, faceMovement: false)) return false;
    _setPose(CatPose.lookDown);
    if (!await _wait(0.4)) return false;

    // E. Dinner.
    _setState(CatGameState.fishEating);
    if (!await _walkTo(KitchenPositions.fishCatEatingPosition, endFacing: -1)) return false;
    _setPose(CatPose.eat);
    if (!await _animate(_sec(GameTimings.fishEating), (t) => plate.fill = 1 - t)) return false;
    _setPose(CatPose.satisfied);
    _addEffect(EffectKind.hearts, _catPosition + const Offset(0, -0.13), duration: _sec(GameTimings.satisfied));
    if (!await _wait(_sec(GameTimings.satisfied))) return false;

    // F. One last sniff of the empty plate, a happy look, and back to idle.
    _setPose(CatPose.sniff);
    if (!await _wait(0.8)) return false;
    _setPose(CatPose.happy);
    if (!await _all([_wait(_sec(GameTimings.happy)), _popAway(plate)])) return false;
    _setState(CatGameState.returningToIdle);
    return _walkTo(KitchenPositions.fishCatReturnPosition);
  }
}
