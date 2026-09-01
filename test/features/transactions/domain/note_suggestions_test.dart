import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/features/transactions/domain/note_suggestions.dart';

void main() {
  test('history comes before the starter notes', () {
    final result = mergeNoteSuggestions(
      history: const ['Bún bò'],
      iconName: 'restaurant',
    );

    expect(result.first, 'Bún bò');
    expect(result, contains('Ăn sáng'));
  });

  test('a note already in the history is not repeated by the defaults', () {
    final result = mergeNoteSuggestions(
      history: const ['ăn TRƯA'],
      iconName: 'restaurant',
    );

    // Dedupe is case-insensitive, and the user's own spelling wins.
    expect(result.where((s) => s.toLowerCase() == 'ăn trưa').length, 1);
    expect(result.first, 'ăn TRƯA');
  });

  test('the query filters both sources', () {
    final result = mergeNoteSuggestions(
      history: const ['Bún bò', 'Cơm tấm'],
      iconName: 'restaurant',
      query: 'cà',
    );

    expect(result, ['Cà phê']);
  });

  test('an unknown icon still returns the history', () {
    final result = mergeNoteSuggestions(
      history: const ['Chi khác'],
      iconName: 'no_such_icon',
    );

    expect(result, ['Chi khác']);
  });

  test('no category yields nothing rather than throwing', () {
    expect(mergeNoteSuggestions(history: const [], iconName: null), isEmpty);
  });
}
