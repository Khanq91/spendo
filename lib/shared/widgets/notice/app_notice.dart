import 'package:flutter/foundation.dart';

/// What a notice is about; decides its dot colour and how long it stays.
enum NoticeKind {
  /// Something completed ("Đã kết nối Google Drive.").
  success,

  /// Neutral information ("Thông báo sẽ hiện sau 5 giây").
  info,

  /// The user should know before going on.
  warning,

  /// Something failed, usually with "Thử lại".
  error,

  /// A completed action that can still be reverted; carries a [NoticeAction]
  /// and keeps a fixed neutral dot rather than a colour of its own.
  undo,
}

/// The text button on the right of an undo notice.
class NoticeAction {
  const NoticeAction(this.label, this.onPressed);

  final String label;
  final VoidCallback onPressed;
}

/// One request to show the banner. A new [id] shows or re-triggers it.
@immutable
class NoticeRequest {
  const NoticeRequest({
    required this.id,
    required this.message,
    required this.kind,
    this.action,
  });

  final int id;
  final String message;
  final NoticeKind kind;
  final NoticeAction? action;

  /// How long the banner stays before it slides away. The original hides
  /// after 2.2s; errors and warnings get a beat more for a longer sentence,
  /// and undo keeps the 5s the SnackBar used to give.
  Duration get displayDuration => switch (kind) {
    NoticeKind.success || NoticeKind.info => const Duration(
      milliseconds: 2200,
    ),
    NoticeKind.warning || NoticeKind.error => const Duration(
      milliseconds: 3200,
    ),
    NoticeKind.undo => const Duration(seconds: 5),
  };
}

/// The one way the app tells the user something in passing.
///
/// Replaces `ScaffoldMessenger.showSnackBar`: no `BuildContext` is needed,
/// so callers no longer capture a messenger before an async gap, and the
/// banner is drawn by [NoticeHost] above the navigator, so it shows over
/// sheets and dialogs too. There is one banner: a request while another is
/// showing swaps the message and restarts the clock, like the original.
abstract final class AppNotice {
  /// The latest request; [NoticeHost] listens to it.
  static final ValueNotifier<NoticeRequest?> requests =
      ValueNotifier<NoticeRequest?>(null);

  static int _nextId = 0;

  static void show(
    String message, {
    NoticeKind kind = NoticeKind.info,
    NoticeAction? action,
  }) {
    requests.value = NoticeRequest(
      id: ++_nextId,
      message: message,
      kind: kind,
      action: action,
    );
  }

  static void success(String message) =>
      show(message, kind: NoticeKind.success);

  static void info(String message) => show(message, kind: NoticeKind.info);

  static void warning(String message) =>
      show(message, kind: NoticeKind.warning);

  static void error(String message) => show(message, kind: NoticeKind.error);

  /// A done-but-revertible action: "Đã xoá …" with a Hoàn tác button.
  static void undo(
    String message, {
    required VoidCallback onUndo,
    String label = 'Hoàn tác',
  }) => show(
    message,
    kind: NoticeKind.undo,
    action: NoticeAction(label, onUndo),
  );

  /// Forget the pending request, so one test cannot leak into the next.
  @visibleForTesting
  static void reset() {
    requests.value = null;
    _nextId = 0;
  }
}
