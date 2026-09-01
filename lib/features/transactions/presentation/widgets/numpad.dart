import 'package:flutter/material.dart';

import '../../../../shared/widgets/spendo/spendo.dart';

/// Thin alias over [SpendoNumpad], kept for the screens that phases 4 and 5
/// still own (budget, loan, wallet forms). New call sites should reach for
/// [SpendoNumpad] directly; this exists so those screens pick up the token
/// keypad now instead of keeping the old bordered grid until their turn.
class Numpad extends StatelessWidget {
  const Numpad({super.key, required this.onKey});

  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) => SpendoNumpad(onKey: onKey);
}
