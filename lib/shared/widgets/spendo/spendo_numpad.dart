import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../motion/motion.dart';

/// Amount keypad: 1-9 / 000 / 0 / ⌫, laid out on the 3-column grid from
/// `02-components.md`.
///
/// [onKey] receives the digits to append, or [Numpad.deleteKey] for backspace.
class SpendoNumpad extends StatelessWidget {
  const SpendoNumpad({
    super.key,
    required this.onKey,
    this.onLongPressDelete,
  });

  /// Sent when backspace is tapped.
  static const deleteKey = '⌫';

  final ValueChanged<String> onKey;

  /// Optional "clear everything" affordance.
  final VoidCallback? onLongPressDelete;

  @override
  Widget build(BuildContext context) {
    const keys = [
      '1', '2', '3', //
      '4', '5', '6',
      '7', '8', '9',
      '000', '0', deleteKey,
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      // 54px tall keys on a typical 360dp-wide screen.
      childAspectRatio: 2.0,
      padding: EdgeInsets.zero,
      children: [for (final key in keys) _NumpadKey(label: key, onKey: onKey, onLongPressDelete: onLongPressDelete)],
    );
  }
}

class _NumpadKey extends StatelessWidget {
  const _NumpadKey({
    required this.label,
    required this.onKey,
    this.onLongPressDelete,
  });

  final String label;
  final ValueChanged<String> onKey;
  final VoidCallback? onLongPressDelete;

  bool get _isDelete => label == SpendoNumpad.deleteKey;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PressableScale(
      deferTapToChild: true,
      child: Material(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onKey(label);
          },
          onLongPress: _isDelete ? onLongPressDelete : null,
          child: Center(
            child: _isDelete
                ? Icon(LucideIcons.delete, size: 22, color: cs.onSurface)
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: label == '000' ? 17 : 23,
                      fontWeight: label == '000'
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: cs.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
