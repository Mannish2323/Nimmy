import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Error recovery view providing a clear explanation and actionable retry path.
/// Follows AGENTS.md §25 (Error Recovery) guidelines to prevent dead-end states.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline_rounded,
    this.retryLabel = 'Try Again',
    this.onRetry,
    this.secondaryLabel,
    this.onSecondary,
    this.compact = false,
  });

  final String title;
  final String message;
  final IconData icon;
  final String retryLabel;
  final VoidCallback? onRetry;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.all(NimmySpacing.md),
        decoration: BoxDecoration(
          color: NimmyColors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(NimmyRadius.lg),
          border: Border.all(color: NimmyColors.red.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, color: NimmyColors.red, size: 24),
            const SizedBox(width: NimmySpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: NimmyColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: NimmyColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: NimmySpacing.sm),
              FilledButton.tonal(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 38),
                  padding: const EdgeInsets.symmetric(horizontal: NimmySpacing.sm),
                ),
                child: Text(retryLabel, style: const TextStyle(fontSize: 12)),
              ),
            ] else if (onSecondary != null && secondaryLabel != null) ...[
              const SizedBox(width: NimmySpacing.sm),
              FilledButton.tonal(
                onPressed: onSecondary,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 38),
                  padding: const EdgeInsets.symmetric(horizontal: NimmySpacing.sm),
                ),
                child: Text(secondaryLabel!, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NimmySpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: NimmyColors.red.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: NimmyColors.red.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, color: NimmyColors.red, size: 34),
            ),
            const SizedBox(height: NimmySpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: NimmySpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: NimmyColors.textSecondary,
                    ),
              ),
            ),
            const SizedBox(height: NimmySpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (secondaryLabel != null && onSecondary != null) ...[
                  OutlinedButton(
                    onPressed: onSecondary,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(100, 48),
                    ),
                    child: Text(secondaryLabel!),
                  ),
                  const SizedBox(width: NimmySpacing.md),
                ],
                if (onRetry != null)
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(retryLabel),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, 48),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
