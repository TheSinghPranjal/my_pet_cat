enum CatActivity {
  feed,
  play,
  catchMouse,
  bathTime,
  brushFur,
  towelDry,
  catchBird,
  climbTree,
  chaseButterflies,
  glassTrouble,
  treatTime,
  fishySurprise,
  wardrobeHide,
  chewCable,
  pillowJump,
}

/// One contextual action button.
class ActivityDefinition {
  const ActivityDefinition(this.activity, this.label, this.semanticLabel, {this.accent});

  final CatActivity activity;
  final String label;
  final String semanticLabel;

  /// Optional paper tint for the button (ARGB); plain white when null.
  final int? accent;
}
