import 'package:flutter/material.dart';

class FeatureGridAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const FeatureGridAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class FeatureGrid extends StatelessWidget {
  final List<FeatureGridAction> actions;

  const FeatureGrid({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: actions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisExtent: 102,
        mainAxisSpacing: 10,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (context, index) => _FeatureTile(action: actions[index]),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final FeatureGridAction action;

  const _FeatureTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 102,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: action.color.withValues(alpha: 0.12),
              ),
              child: Icon(action.icon, size: 26, color: action.color),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                action.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
