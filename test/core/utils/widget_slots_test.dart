import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/utils/widget_sync.dart';
import 'package:spendo/features/categories/domain/category.dart';

Category _cat(String id, int order) => Category(
  id: id,
  name: id,
  colorHex: '#FF6B6B',
  iconName: 'restaurant',
  isDefault: false,
  isIncome: false,
  sortOrder: order,
);

final _five = [
  _cat('a', 0),
  _cat('b', 1),
  _cat('c', 2),
  _cat('d', 3),
  _cat('e', 4),
];

List<String?> _ids(List<Category?> slots) => [for (final c in slots) c?.id];

void main() {
  test('with nothing pinned it takes the first four in order', () {
    expect(_ids(resolveWidgetSlots(const [], _five)), ['a', 'b', 'c', 'd']);
  });

  test('pinned ids keep their slot and are not also used as filler', () {
    // 'e' is pinned to slot 0, so the fallbacks skip it and start at 'a'.
    expect(_ids(resolveWidgetSlots(const ['e', '', '', ''], _five)), [
      'e',
      'a',
      'b',
      'c',
    ]);
  });

  test('a pinned id that no longer exists falls back rather than blanking', () {
    // The category was deleted elsewhere; the slot must not show a stale name.
    expect(_ids(resolveWidgetSlots(const ['gone', '', '', ''], _five)), [
      'a',
      'b',
      'c',
      'd',
    ]);
  });

  test('a duplicate pin is honoured once, and the rest fall back', () {
    expect(_ids(resolveWidgetSlots(const ['a', 'a', '', ''], _five)), [
      'a',
      'b',
      'c',
      'd',
    ]);
  });

  test('fewer than four categories leaves the spare slots null', () {
    // The bug this replaces: the old code filled the gap with four hard-coded
    // names, so a user with two categories saw two that were not theirs.
    expect(_ids(resolveWidgetSlots(const [], [_cat('a', 0), _cat('b', 1)])), [
      'a',
      'b',
      null,
      null,
    ]);
  });

  test('empty slots hold their position, they do not collapse', () {
    // The 2×2 grid is positional: pinning to slot 3 must not slide it up.
    final slots = resolveWidgetSlots(const ['', '', 'a', ''], [_cat('a', 0)]);
    expect(_ids(slots), [null, null, 'a', null]);
  });

  test('no categories at all yields four blanks, not an error', () {
    expect(_ids(resolveWidgetSlots(const [], const [])), [
      null,
      null,
      null,
      null,
    ]);
  });

  test('it always returns exactly four slots', () {
    for (final pinned in [
      const <String>[],
      const ['a'],
      const ['a', 'b', 'c', 'd', 'e'],
    ]) {
      expect(resolveWidgetSlots(pinned, _five), hasLength(4));
    }
  });
}
