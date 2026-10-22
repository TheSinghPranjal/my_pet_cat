import '../models/activity_definition.dart';
import '../scripting/script_step.dart';
import 'bathroom/bath_scripts.dart';
import 'bedroom/bedroom_scripts.dart';
import 'kitchen/kitchen_scripts.dart';
import 'living_room/living_room_scripts.dart';
import 'living_area/home_scripts.dart';
import 'outdoors/outdoor_scripts.dart';
import 'park/park_scripts.dart';

/// The script each activity plays.
abstract final class ActivityScripts {
  static ActivityScript of(CatActivity activity) => switch (activity) {
    CatActivity.feed => HomeScripts.feed,
    CatActivity.play => HomeScripts.play,
    CatActivity.catchMouse => HomeScripts.catchMouse,
    CatActivity.bathTime => BathScripts.bathTime,
    CatActivity.brushFur => BathScripts.brushFur,
    CatActivity.towelDry => BathScripts.towelDry,
    CatActivity.catchBird => OutdoorScripts.catchBird,
    CatActivity.climbTree => OutdoorScripts.climbTree,
    CatActivity.chaseButterflies => OutdoorScripts.chaseButterflies,
    CatActivity.glassTrouble => KitchenScripts.glassTrouble,
    CatActivity.treatTime => KitchenScripts.treatTime,
    CatActivity.fishySurprise => KitchenScripts.fishySurprise,
    CatActivity.wardrobeHide => BedroomScripts.wardrobeHide,
    CatActivity.chewCable => BedroomScripts.chewCable,
    CatActivity.pillowJump => BedroomScripts.pillowJump,
    CatActivity.fishBowl => LivingRoomScripts.fishBowl,
    CatActivity.purr => LivingRoomScripts.purr,
    CatActivity.windowWatch => LivingRoomScripts.windowWatch,
    CatActivity.duckPond => ParkScripts.duckPond,
    CatActivity.leafPile => ParkScripts.leafPile,
    CatActivity.benchPigeon => ParkScripts.benchPigeon,
  };
}
