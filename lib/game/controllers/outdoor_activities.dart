part of 'cat_game_controller.dart';

extension _OutdoorActivities on CatGameController {
  Future<bool> _catchBirdSequence() async {
    final bird = _spawn(ObjectKind.bird, OutdoorPositions.birdSpawnPosition, facing: -1);
    _focus = bird;
    if (!await _appear(bird)) return false;

    // The kitten notices the bird, then sneaks up.
    if (!await _turnToward(bird.position)) return false;
    _setPose(CatPose.lookUp);
    if (!await _wait(0.6)) return false;
    if (!await _walkTo(OutdoorPositions.catBirdStartPosition, endFacing: 1, endPose: CatPose.crouch)) {
      return false;
    }

    // The bird hops along its path; the kitten follows.
    if (!await _moveObject(bird, OutdoorPositions.birdWaypointA, 0.55, arc: 0.07)) return false;
    if (!await _all([
      _moveObject(bird, OutdoorPositions.birdWaypointB, 0.4, arc: 0.025),
      _walkTo(OutdoorPositions.catBirdPursuitPosition, endFacing: 1, endPose: CatPose.crouch),
    ])) {
      return false;
    }
    if (!await _moveObject(bird, OutdoorPositions.birdWaypointC, 0.4, arc: 0.025)) return false;
    if (!await _wait(0.3)) return false;

    // It flutters up, the kitten pounces underneath, and the bird flies away
    // safely.
    bird.airborne = true;
    if (!await _moveObject(bird, OutdoorPositions.birdFlutterPosition, 0.5, faceMovement: false)) {
      return false;
    }
    if (!await _all([
      _pounce(OutdoorPositions.catBirdPounceTarget, height: 18).then((ok) {
        if (ok) _setPose(CatPose.lookUp);
        return ok;
      }),
      _after(0.15, () => _moveObject(bird, OutdoorPositions.birdExitPosition, 1.3, curve: Curves.easeIn)),
    ])) {
      return false;
    }
    _remove(bird);

    if (!await _wait(0.6)) return false;
    _setPose(CatPose.sit);
    if (!await _wait(0.9)) return false;

    _setState(CatGameState.returningToIdle);
    return _walkTo(OutdoorPositions.catBirdReturnPosition);
  }

  Future<bool> _climbTreeSequence() async {
    final climb = _sec(GameTimings.climbSegment);
    if (!await _walkTo(OutdoorPositions.treeBasePosition, endFacing: -1, endPose: CatPose.lookUp)) {
      return false;
    }
    if (!await _wait(0.8)) return false;

    // Up the trunk and onto the low branch.
    _setPose(CatPose.climb);
    if (!await _moveCat(OutdoorPositions.treeTrunkPosition, climb)) return false;
    if (!await _turnTo(1)) return false;
    if (!await _moveCat(OutdoorPositions.treeLowBranchPosition, climb)) return false;
    _setPose(CatPose.sit);
    if (!await _wait(0.5)) return false;

    // Higher, to the top branch.
    if (!await _turnTo(-1)) return false;
    _setPose(CatPose.climb);
    if (!await _moveCat(OutdoorPositions.treeMiddleBranchPosition, climb)) return false;
    if (!await _turnTo(1)) return false;
    if (!await _moveCat(OutdoorPositions.treeHighBranchPosition, climb)) return false;

    // Sit, look around happily while a few leaves drift down.
    _setPose(CatPose.sit);
    _addEffect(EffectKind.leaves, OutdoorPositions.leafFallPosition);
    if (!await _wait(0.9)) return false;
    if (!await _turnTo(-1)) return false;
    if (!await _wait(0.8)) return false;
    if (!await _turnTo(1)) return false;
    _setPose(CatPose.happy);
    if (!await _wait(_sec(GameTimings.happy))) return false;
    if (!await _fadeEffects()) return false;

    // Back down the same way.
    if (!await _turnTo(-1)) return false;
    _setPose(CatPose.climb);
    if (!await _moveCat(OutdoorPositions.treeMiddleBranchPosition, climb)) return false;
    if (!await _moveCat(OutdoorPositions.treeTrunkPosition, climb)) return false;
    if (!await _moveCat(OutdoorPositions.treeBasePosition, climb * 0.8)) return false;
    _setPose(CatPose.idle);

    _setState(CatGameState.returningToIdle);
    return _walkTo(OutdoorPositions.treeClimbReturnPosition);
  }

  Future<bool> _chaseButterfliesSequence() async {
    final butterfly = _spawn(ObjectKind.butterfly, OutdoorPositions.butterflySpawnPosition)
      ..airborne = true;
    _focus = butterfly;
    if (!await _appear(butterfly)) return false;

    if (!await _turnToward(butterfly.position)) return false;
    _setPose(CatPose.lookUp);
    if (!await _wait(0.6)) return false;
    if (!await _walkTo(OutdoorPositions.catButterflyStartPosition,
        endFacing: 1, endPose: CatPose.lookUp)) {
      return false;
    }

    // A looping flight; the kitten trots after it.
    if (!await _all([
      _moveObject(butterfly, OutdoorPositions.butterflyWaypointA, 1.0, wobble: 0.015),
      _walkTo(OutdoorPositions.catButterflyPursuitPosition, endFacing: 1, endPose: CatPose.lookUp),
    ])) {
      return false;
    }
    if (!await _moveObject(butterfly, OutdoorPositions.butterflyWaypointB, 0.8, wobble: 0.012)) {
      return false;
    }
    if (!await _moveObject(butterfly, OutdoorPositions.butterflyWaypointC, 0.7, wobble: 0.01)) {
      return false;
    }

    // Two gentle swats; it flutters just out of reach.
    _setPose(CatPose.swat);
    if (!await _swipePaw()) return false;
    if (!await _all([
      _swipePaw(),
      _moveObject(butterfly, OutdoorPositions.butterflyFlutterPosition, 0.6, curve: Curves.easeOut),
    ])) {
      return false;
    }
    _setPose(CatPose.lookUp);
    if (!await _moveObject(butterfly, OutdoorPositions.butterflyExitPosition, 1.4,
        wobble: 0.02, curve: Curves.easeIn)) {
      return false;
    }
    _remove(butterfly);

    _setPose(CatPose.relax);
    if (!await _wait(1.0)) return false;

    _setState(CatGameState.returningToIdle);
    return _walkTo(OutdoorPositions.catButterflyReturnPosition);
  }
}
