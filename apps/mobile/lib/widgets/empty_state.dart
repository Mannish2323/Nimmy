import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'glow_button.dart';

class NimmyEmptyState extends StatelessWidget {
  const NimmyEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NimmySpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NimmyColors.purple.withValues(alpha: 0.1),
                border: Border.all(
                  color: NimmyColors.purple.withValues(alpha: 0.28),
                ),
              ),
              child: Icon(icon, color: NimmyColors.purpleLight, size: 30),
            ),
            const SizedBox(height: NimmySpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: NimmySpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: NimmySpacing.lg),
              GlowButton(
                label: actionLabel!,
                icon: Icons.auto_awesome_rounded,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
