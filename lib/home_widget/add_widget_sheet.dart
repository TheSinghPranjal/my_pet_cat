import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../game/sketch/sketch.dart';
import '../game/widgets/game_action_button.dart';
import 'pet_home_widget_service.dart';

/// Explains how to put the kitten on the home screen. The OS controls widget
/// placement, so this only offers the launcher's own prompt (where Android
/// supports it) or step-by-step instructions; it never claims success.
class AddWidgetSheet extends StatefulWidget {
  const AddWidgetSheet({super.key, this.service});

  final PetHomeWidgetService? service;

  static Future<void> show(BuildContext context) =>
      showDialog<void>(context: context, builder: (_) => const AddWidgetSheet());

  @override
  State<AddWidgetSheet> createState() => _AddWidgetSheetState();
}

class _AddWidgetSheetState extends State<AddWidgetSheet> {
  late final _service = widget.service ?? PetHomeWidgetService.instance;
  bool _canPin = false;
  String? _note;

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    if (!_isIOS) {
      _service.canRequestPin().then((value) {
        if (mounted) setState(() => _canPin = value);
      });
    }
  }

  Future<void> _pin() async {
    final requested = await _service.requestPin();
    if (!mounted) return;
    setState(() => _note = requested
        ? 'Your home screen will ask you to confirm where to put Kitty.'
        : "Your launcher can't add widgets from apps. Please follow the steps above.");
  }

  @override
  Widget build(BuildContext context) {
    const ink = TextStyle(color: SketchColors.ink, fontWeight: FontWeight.w700);
    final steps = _isIOS
        ? const [
            'Touch and hold an empty spot on your Home Screen until the apps jiggle.',
            'Tap Edit, then Add Widget.',
            'Search for "My Pet Cat", pick a size and tap Add Widget.',
          ]
        : const [
            'Touch and hold an empty spot on your home screen.',
            'Tap Widgets and find My Pet Cat.',
            'Drag the size you like onto your home screen.',
          ];
    return Dialog(
      backgroundColor: SketchColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: SketchColors.ink, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Keep Kitty close!', style: ink.copyWith(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
              'Add the My Pet Cat widget to your home screen for one-tap play.',
              style: TextStyle(color: SketchColors.pencil, fontSize: 15, height: 1.3),
            ),
            const SizedBox(height: 12),
            for (final (i, step) in steps.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${i + 1}. $step', style: const TextStyle(color: SketchColors.pencil, fontSize: 14)),
              ),
            if (_note != null) ...[
              const SizedBox(height: 6),
              Text(_note!, style: const TextStyle(color: SketchColors.coral, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_canPin && _note == null)
                  SizedBox(
                    height: 44,
                    width: 150,
                    child: SketchPressable(
                      enabled: true,
                      semanticLabel: 'Add widget',
                      onPressed: _pin,
                      child: const CustomPaint(
                        painter: SketchFramePainter(radius: 0.4, fill: SketchColors.coralLight),
                        child: Center(child: Text('Add widget', style: ink)),
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Done', style: ink.copyWith(fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
