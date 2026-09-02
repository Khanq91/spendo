import 'package:flutter/material.dart';

import '../../../core/theme/spendo_colors.dart';
import 'app_notice.dart';
import 'notice_slide_in.dart';

/// Draws the app's one notice banner over everything else.
///
/// Mounted through `MaterialApp.builder`, so it sits above the navigator —
/// a notice raised from inside a bottom sheet shows over the sheet instead of
/// behind it, which is where a SnackBar used to land. The banner emerges
/// from under the status bar and hugs the top of the safe area.
class NoticeHost extends StatelessWidget {
  const NoticeHost({super.key, required this.child});

  final Widget child;

  static Color dotColorFor(BuildContext context, NoticeKind kind) {
    final theme = Theme.of(context);
    return switch (kind) {
      NoticeKind.success => theme.spendo.income,
      NoticeKind.info => theme.spendo.brand,
      NoticeKind.warning => theme.spendo.warning,
      NoticeKind.error => theme.colorScheme.error,
      // Revertible actions keep one neutral dot rather than a colour of
      // their own.
      NoticeKind.undo => theme.colorScheme.outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: ClipRect(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: ValueListenableBuilder<NoticeRequest?>(
                  valueListenable: AppNotice.requests,
                  builder: (context, request, _) {
                    final theme = Theme.of(context);
                    final cs = theme.colorScheme;
                    return NoticeSlideIn(
                      requestId: request?.id ?? 0,
                      message: request?.message ?? '',
                      displayDuration:
                          request?.displayDuration ??
                          const Duration(milliseconds: 2200),
                      action: request?.action,
                      // The SnackBar's contrast pairing, so the banner reads
                      // the same way on both themes.
                      backgroundColor: cs.inverseSurface,
                      borderColor: cs.inverseSurface,
                      textColor: cs.onInverseSurface,
                      dotColor: dotColorFor(
                        context,
                        request?.kind ?? NoticeKind.info,
                      ),
                      actionColor: cs.inversePrimary,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
