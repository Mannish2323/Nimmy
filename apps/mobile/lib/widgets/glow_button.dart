import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class GlowButton extends StatelessWidget {
  const GlowButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: NimmyColors.primaryGradient,
        borderRadius: BorderRadius.circular(NimmyRadius.md),
        boxShadow: onPressed == null
            ? null
            : const [
                BoxShadow(
                  color: NimmyColors.purpleGlow,
                  blurRadius: 22,
                  spreadRadius: -4,
                ),
              ],
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: NimmyColors.surfaceSoft,
          shadowColor: Colors.transparent,
          minimumSize: Size(compact ? 0 : 48, compact ? 44 : 52),
        ),
        icon: Icon(icon, size: 19),
        label: Text(label),
      ),
    );
  }
}
