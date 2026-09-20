import 'dart:ui';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Glassmorphic dialog adhering to NIMMY design system tokens.
/// Meets accessibility semantics, touch target sizes (>=48dp), and reduced motion.
class NimmyDialog extends StatelessWidget {
  const NimmyDialog({
    super.key,
    required this.title,
    required this.content,
    this.icon,
    this.iconColor = NimmyColors.purple,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  final String title;
  final Widget content;
  final IconData? icon;
  final Color iconColor;
  final String confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    IconData? icon = Icons.help_outline_rounded,
    Color iconColor = NimmyColors.purple,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => NimmyDialog(
        title: title,
        icon: icon,
        iconColor: iconColor,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
        content: Text(
          message,
          style: Theme.of(ctx).textTheme.bodyMedium,
        ),
      ),
    );
  }

  static Future<void> showAlert(
    BuildContext context, {
    required String title,
    required String message,
    IconData? icon = Icons.info_outline_rounded,
    Color iconColor = NimmyColors.cyan,
    String buttonLabel = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => NimmyDialog(
        title: title,
        icon: icon,
        iconColor: iconColor,
        confirmLabel: buttonLabel,
        cancelLabel: null,
        onConfirm: () => Navigator.of(ctx).pop(),
        content: Text(
          message,
          style: Theme.of(ctx).textTheme.bodyMedium,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: NimmySpacing.xl,
        vertical: NimmySpacing.xxl,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(NimmyRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(NimmySpacing.xl),
            decoration: BoxDecoration(
              color: NimmyColors.surfaceRaised.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(NimmyRadius.xl),
              border: Border.all(
                color: isDestructive
                    ? NimmyColors.red.withValues(alpha: 0.5)
                    : NimmyColors.borderBright,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Semantics(
              label: title,
              explicitChildNodes: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(NimmyRadius.md),
                      ),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                    const SizedBox(height: NimmySpacing.md),
                  ],
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: NimmySpacing.sm),
                  Flexible(
                    child: SingleChildScrollView(
                      child: content,
                    ),
                  ),
                  const SizedBox(height: NimmySpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (cancelLabel != null) ...[
                        OutlinedButton(
                          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(80, 48),
                            padding: const EdgeInsets.symmetric(horizontal: NimmySpacing.md),
                          ),
                          child: Text(cancelLabel!),
                        ),
                        const SizedBox(width: NimmySpacing.sm),
                      ],
                      FilledButton(
                        onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: isDestructive ? NimmyColors.red : NimmyColors.purple,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(88, 48),
                          padding: const EdgeInsets.symmetric(horizontal: NimmySpacing.lg),
                        ),
                        child: Text(confirmLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
