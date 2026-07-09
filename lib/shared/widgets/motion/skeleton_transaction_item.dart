import 'package:flutter/material.dart';

import 'skeleton_block.dart';

class SkeletonTransactionItem extends StatelessWidget {
  const SkeletonTransactionItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const SkeletonBlock(width: 42, height: 42),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: 120, height: 14),
                SizedBox(height: 8),
                SkeletonBlock(width: 72, height: 12),
              ],
            ),
          ),
          SkeletonBlock(width: 86, height: 14),
        ],
      ),
    );
  }
}
