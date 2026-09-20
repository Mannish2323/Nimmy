import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Shimmer skeleton loader matching NIMMY dark surfaces.
/// Automatically disables animation when system reduced motion is active.
class LoadingShimmer extends StatefulWidget {
  const LoadingShimmer({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = NimmyRadius.md,
  });

  final double? width;
  final double height;
  final double borderRadius;

  static Widget card({double height = 80, double? width}) {
    return LoadingShimmer(
      height: height,
      width: width,
      borderRadius: NimmyRadius.lg,
    );
  }

  static Widget circle({double size = 48}) {
    return LoadingShimmer(
      height: size,
      width: size,
      borderRadius: NimmyRadius.pill,
    );
  }

  static Widget listTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NimmySpacing.xs),
      child: Row(
        children: [
          LoadingShimmer.circle(size: 40),
          const SizedBox(width: NimmySpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingShimmer(height: 14, width: 140, borderRadius: NimmyRadius.sm),
                const SizedBox(height: NimmySpacing.xs),
                LoadingShimmer(height: 11, width: 220, borderRadius: NimmyRadius.sm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    } else {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    if (reducedMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: NimmyColors.surfaceSoft,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: const [
                NimmyColors.surface,
                NimmyColors.surfaceSoft,
                NimmyColors.surface,
              ],
            ),
            border: Border.all(
              color: NimmyColors.border.withValues(alpha: 0.5),
            ),
          ),
        );
      },
    );
  }
}
