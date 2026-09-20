import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

enum SnackbarType {
  success,
  error,
  warning,
  info;

  Color get color => switch (this) {
        success => NimmyColors.green,
        error => NimmyColors.red,
        warning => NimmyColors.amber,
        info => NimmyColors.cyan,
      };

  IconData get icon => switch (this) {
        success => Icons.check_circle_outline_rounded,
        error => Icons.error_outline_rounded,
        warning => Icons.warning_amber_rounded,
        info => Icons.info_outline_rounded,
      };
}

/// Floating snackbar designed to integrate with the NIMMY glassmorphic theme.
class NimmySnackbar {
  NimmySnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      duration: duration,
      margin: const EdgeInsets.fromLTRB(
        NimmySpacing.lg,
        0,
        NimmySpacing.lg,
        NimmySpacing.lg,
      ),
      padding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: NimmySpacing.md,
          vertical: NimmySpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: NimmyColors.surfaceRaised.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(NimmyRadius.lg),
          border: Border.all(
            color: type.color.withValues(alpha: 0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: type.color.withValues(alpha: 0.15),
              blurRadius: 18,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Semantics(
          liveRegion: true,
          label: '${type.name}: $message',
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(type.icon, color: type.color, size: 18),
              ),
              const SizedBox(width: NimmySpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: NimmyColors.textPrimary,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: NimmySpacing.xs),
                TextButton(
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                    onAction();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: type.color,
                    padding: const EdgeInsets.symmetric(horizontal: NimmySpacing.sm),
                    minimumSize: const Size(48, 36),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    messenger.showSnackBar(snackBar);
  }

  static void showSuccess(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    show(context, message: message, type: SnackbarType.success, actionLabel: actionLabel, onAction: onAction);
  }

  static void showError(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    show(context, message: message, type: SnackbarType.error, actionLabel: actionLabel, onAction: onAction);
  }

  static void showWarning(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    show(context, message: message, type: SnackbarType.warning, actionLabel: actionLabel, onAction: onAction);
  }

  static void showInfo(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    show(context, message: message, type: SnackbarType.info, actionLabel: actionLabel, onAction: onAction);
  }
}
