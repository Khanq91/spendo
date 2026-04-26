import 'package:flutter/material.dart';
import '../../features/transactions/presentation/widgets/add_transaction_sheet.dart';

Future<void> showAddTransactionSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const AddTransactionSheet(),
  );
}

class GlobalFab extends StatelessWidget {
  const GlobalFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'global_fab',
      onPressed: () => showAddTransactionSheet(context),
      shape: const CircleBorder(),
      child: const Icon(Icons.add, size: 28),
    );
  }
}