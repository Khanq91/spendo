import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// The 36×4 pill at the top of every bottom sheet.
///
/// Replaces the fifteen inline copies the audit found
/// (`06-inconsistencies.md`).
class SpendoDragHandle extends StatelessWidget {
  const SpendoDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: ShapeDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        shape: const StadiumBorder(),
      ),
    );
  }
}

/// Bottom-sheet shell: token background, 28px top corners, drag handle, and
/// padding that clears the keyboard.
///
/// Wrap the *content* of a `showModalBottomSheet` with this; use
/// [SpendoSheet.showModal] to get the barrier configuration too.
class SpendoSheet extends StatelessWidget {
  const SpendoSheet({
    super.key,
    required this.child,
    this.header,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 16),
    this.showDragHandle = true,
  });

  final Widget child;

  /// Row shown under the handle — typically [SpendoSheetHeader].
  final Widget? header;
  final EdgeInsets padding;
  final bool showDragHandle;

  /// Opens [builder] as a modal sheet already wearing the sheet tokens.
  static Future<T?> showModal<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusSheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDragHandle) const SpendoDragHandle(),
              if (header != null) header!,
              Flexible(child: Padding(padding: padding, child: child)),
            ],
          ),
        ),
      ),
    );
  }
}

/// `Huỷ — title — action` row used at the top of the form sheets.
class SpendoSheetHeader extends StatelessWidget {
  const SpendoSheetHeader({
    super.key,
    required this.title,
    this.onCancel,
    this.action,
    this.cancelLabel = 'Huỷ',
  });

  final String title;
  final VoidCallback? onCancel;

  /// Trailing widget — usually a primary [SpendoButton].
  final Widget? action;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          if (onCancel != null)
            GestureDetector(
              onTap: onCancel,
              behavior: HitTestBehavior.opaque,
              child: Text(
                cancelLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (action != null) action! else const SizedBox(width: 40),
        ],
      ),
    );
  }
}
