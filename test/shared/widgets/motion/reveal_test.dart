import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/shared/widgets/motion/motion.dart';

const _rowHeight = 100.0;

Widget _row(Object id) => RevealItem(
  id: id,
  child: SizedBox(height: _rowHeight, child: Text('row $id')),
);

Widget _list(List<Object> ids, {bool reduceMotion = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(
        body: RevealScope(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [for (final id in ids) _row(id)],
          ),
        ),
      ),
    ),
  );
}

double _opacityOf(WidgetTester tester, Object id) => tester
    .widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('row $id'),
            matching: find.byType(FadeTransition),
          )
          .first,
    )
    .opacity
    .value;

void main() {
  final ids = List<Object>.generate(30, (i) => i);

  testWidgets('rows in the first viewport reveal top to bottom, staggered', (
    tester,
  ) async {
    await tester.pumpWidget(_list(ids));
    // The sweep runs in a post-frame callback; nothing has moved yet.
    await tester.pump();
    expect(_opacityOf(tester, 0), 0);

    await tester.pump(const Duration(milliseconds: 100));
    expect(_opacityOf(tester, 0), greaterThan(0));
    // Row 3 waits 3 × 80ms before its own 260ms entrance.
    expect(_opacityOf(tester, 3), 0);

    await tester.pumpAndSettle();
    for (final id in [0, 1, 2, 3, 4, 5]) {
      expect(_opacityOf(tester, id), 1, reason: 'row $id settled');
    }
  });

  testWidgets('a row reveals when scrolled into view, and only once', (
    tester,
  ) async {
    await tester.pumpWidget(_list(ids));
    await tester.pumpAndSettle();
    expect(find.text('row 10'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pump();
    // Newly built rows start hidden until the sweep judges them visible.
    expect(_opacityOf(tester, 10), lessThan(1));
    await tester.pumpAndSettle();
    expect(_opacityOf(tester, 10), 1);

    // Scroll away far enough to recycle the row, then back: no replay.
    await tester.drag(find.byType(ListView), const Offset(0, 1600));
    await tester.pumpAndSettle();
    expect(find.text('row 10'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pump();
    expect(_opacityOf(tester, 10), 1);
  });

  testWidgets('a row keeps its revealed state when the list rebuilds', (
    tester,
  ) async {
    var visible = ids;
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RevealScope(
            child: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [for (final id in visible) _row(id)],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Deleting row 0 shifts every index; identity is by id, so row 1 does
    // not pop in again in row 0's slot.
    rebuild(() => visible = ids.sublist(1));
    await tester.pump();
    expect(find.text('row 0'), findsNothing);
    expect(_opacityOf(tester, 1), 1);
  });

  testWidgets('reduce motion shows rows at once', (tester) async {
    await tester.pumpWidget(_list(ids, reduceMotion: true));
    await tester.pump();
    expect(_opacityOf(tester, 0), 1);
    expect(_opacityOf(tester, 5), 1);
  });

  testWidgets('a RevealItem without a scope simply renders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ListView(children: [_row('solo')]))),
    );
    await tester.pump();
    expect(_opacityOf(tester, 'solo'), 1);
  });
}
