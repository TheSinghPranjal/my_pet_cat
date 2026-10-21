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
}

/// One contextual action button.
class ActivityDefinition {
  const ActivityDefinition(this.activity, this.label, this.semanticLabel);

  final CatActivity activity;
  final String label;
  final String semanticLabel;
}
