/// `1.250.000 ₫`, or the digits alone when [withSymbol] is false.
///
/// The symbol is dropped where a row already repeats it — the Stats summary
/// puts three totals on one line, and three ₫ do not fit a 360dp screen.
String formatVND(int amount, {bool withSymbol = true}) {
  final digits = amount.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
  return withSymbol ? '$digits ₫' : digits;
}
