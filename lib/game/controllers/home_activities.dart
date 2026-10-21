part of 'cat_game_controller.dart';

extension _HomeActivities on CatGameController {
  Future<bool> _feedSequence() async {
    final bowl = _spawn(ObjectKind.bowl, HomePositions.bowlPosition);
    if (!await _appear(bowl)) return false;
    if (!await _walkTo(HomePositions.feedingPosition, endFacing: -1)) return false;

    _setState(CatGameState.eating);
    _setPose(CatPose.eat);
    if (!await _animate(_sec(GameTimings.eating), (t) => bowl.fill = 1 - 0.8 * t)) {
      return false;
    }

    _setPose(CatPose.happy);
    if (!await _all([_wait(_sec(GameTimings.happy)), _popAway(bowl)])) return false;

    _setState(CatGameState.returningFromFood);
    return _walkTo(HomePositions.returnPosition);
  }

  Future<bool> _playSequence() async {
    final yarn = _spawn(ObjectKind.yarn, HomePositions.yarnStartPosition);
    _focus = yarn;
    if (!await _appear(yarn)) return false;
    if (!await _walkTo(HomePositions.playPosition, endFacing: 1, endPose: CatPose.play)) {
      return false;
    }

    _setState(CatGameState.playing);
    // 1. The ball rolls away to the right while the kitten watches it.
    if (!await _rollYarn(yarn, HomePositions.yarnWaypoints[0], GameTimings.yarnRollOut)) {
      return false;
    }
    // 2. The kitten scoots after it.
    if (!await _walkTo(HomePositions.chasePosition, endPose: CatPose.play)) return false;
    // 3. The ball rolls a little way back.
    if (!await _rollYarn(yarn, HomePositions.yarnWaypoints[1], GameTimings.yarnRollBack)) {
      return false;
    }
    // 4. Two paw swipes; the second bats the ball to its resting spot.
    if (!await _swipePaw()) return false;
    if (!await _all([
      _swipePaw(),
      _rollYarn(yarn, HomePositions.yarnEndPosition, GameTimings.yarnSettle),
    ])) {
      return false;
    }

    _setPose(CatPose.happy);
    if (!await _all([_wait(_sec(GameTimings.happy)), _popAway(yarn)])) return false;

    _setState(CatGameState.returningFromPlay);
    return _walkTo(HomePositions.returnPosition);
  }

  Future<bool> _rollYarn(SpawnedObject yarn, Offset to, Duration duration) {
    final from = yarn.position;
    final spin = yarn.rotation;
    return _animate(_sec(duration), (t) {
      yarn.position = Offset.lerp(from, to, Curves.easeOutCubic.transform(t))!;
      yarn.rotation = spin + (yarn.position.dx - from.dx) / GameSizes.yarnRadiusNormalized;
    });
  }

  Future<bool> _catchMouseSequence() async {
    // The mouse peeks out of its hole and sniffs around.
    final mouse = _spawn(ObjectKind.mouse, HomePositions.mouseSpawnPosition);
    _focus = mouse;
    _puff(HomePositions.mouseSpawnPosition);
    if (!await _appear(mouse)) return false;
    if (!await _wait(_sec(GameTimings.mouseSniff))) return false;

    // The kitten sneaks closer and crouches.
    if (!await _walkTo(HomePositions.catMouseApproachPosition,
        endFacing: -1, endPose: CatPose.crouch)) {
      return false;
    }
    if (!await _wait(0.6)) return false;

    // The mouse scurries A -> B -> C; the kitten follows fixed pursuit spots.
    if (!await _moveObject(mouse, HomePositions.mouseWaypointA, 0.5)) return false;
    if (!await _all([
      _moveObject(mouse, HomePositions.mouseWaypointB, 0.55),
      _walkTo(HomePositions.catMousePursuitPositions[0], endFacing: -1, endPose: CatPose.crouch),
    ])) {
      return false;
    }
    if (!await _all([
      _moveObject(mouse, HomePositions.mouseWaypointC, 0.5),
      _walkTo(HomePositions.catMousePursuitPositions[1], endFacing: -1, endPose: CatPose.crouch),
    ])) {
      return false;
    }
    if (!await _wait(0.35)) return false;

    // Pounce! The mouse darts home just in time.
    if (!await _all([
      _pounce(HomePositions.catMousePounceTarget),
      _after(0.12, () => _moveObject(mouse, HomePositions.mouseFinalPosition, 0.4, curve: Curves.easeIn)),
    ])) {
      return false;
    }
    _puff(HomePositions.mouseFinalPosition);
    _setPose(CatPose.surprised);
    if (!await _popAway(mouse)) return false;

    // Where did it go? Look around and blink.
    if (!await _wait(0.3)) return false;
    if (!await _turnTo(1)) return false;
    if (!await _wait(0.45)) return false;
    if (!await _turnTo(-1)) return false;
    if (!await _wait(0.5)) return false;

    _setState(CatGameState.returningToIdle);
    return _walkTo(HomePositions.catMouseReturnPosition);
  }
}
