import 'package:flutter/material.dart';

import '../controllers/cat_game_controller.dart';
import '../sketch/sketch.dart';

/// Small notebook-style settings card.
class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key, required this.controller});

  final CatGameController controller;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  @override
  Widget build(BuildContext context) {
    const ink = TextStyle(color: SketchColors.ink, fontWeight: FontWeight.w600);
    return Dialog(
      backgroundColor: SketchColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: SketchColors.ink, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: ink.copyWith(fontSize: 22)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: Text('Let kitty wander around', style: ink)),
                Switch(
                  value: widget.controller.wanderEnabled,
                  activeTrackColor: SketchColors.ink,
                  onChanged: (value) => setState(() => widget.controller.wanderEnabled = value),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Done', style: ink.copyWith(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
