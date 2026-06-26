import 'package:flutter/material.dart';

import '../widgets/feature_grid.dart';
import '../widgets/home_feature_actions.dart';

class AllFeaturesScreen extends StatelessWidget {
  const AllFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = buildAllFeatureSections(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tất cả tính năng',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 18),
        itemBuilder: (context, index) {
          final section = sections[index];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 8),
                child: Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              FeatureGrid(actions: section.actions),
            ],
          );
        },
      ),
    );
  }
}
