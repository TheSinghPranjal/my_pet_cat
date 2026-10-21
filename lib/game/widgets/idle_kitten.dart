import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../animations/cat_animations.dart';
import '../models/cat_game_state.dart';
import '../models/cat_look.dart';
import 'cat_character.dart';

/// The same kitten as in the game, animating on its own clock. Used on the
/// splash and menu screens, outside the game controller.
class IdleKitten extends StatefulWidget {
  const IdleKitten({
    super.key,
    required this.width,
    this.pose = CatPose.idle,
    this.loopSeconds,
    this.facing = 1,
    this.look,
  });

  final double width;
  final CatPose pose;

  /// When set, the pose restarts every [loopSeconds] (e.g. repeated happy
  /// hops on the splash).
  final double? loopSeconds;
  final double facing;

  /// Drawing style; follows the player's choice when null.
  final CatLook? look;

  @override
  State<IdleKitten> createState() => _IdleKittenState();
}

class _IdleKittenState extends State<IdleKitten> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() => _time = elapsed.inMicroseconds / Duration.microsecondsPerSecond);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loop = widget.loopSeconds;
    final frame = catFrameFor(
      pose: widget.pose,
      time: _time,
      poseTime: loop == null ? _time : _time % loop,
      walkPhase: 0,
      gaze: 0,
      swipe: 0,
    );
    return CatCharacter(frame: frame, facing: widget.facing, width: widget.width, look: widget.look);
  }
}
