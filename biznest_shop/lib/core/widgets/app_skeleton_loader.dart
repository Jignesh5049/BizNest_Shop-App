import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppSkeletonLoader extends StatefulWidget {
  final double? height;
  final BorderRadius? borderRadius;

  const AppSkeletonLoader({super.key, this.height, this.borderRadius});

  @override
  State<AppSkeletonLoader> createState() => _AppSkeletonLoaderState();
}

class _AppSkeletonLoaderState extends State<AppSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(12);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final offset = _controller.value;
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (2 * offset), -0.2),
              end: Alignment(1.0 + (2 * offset), 0.2),
              colors: [AppColors.gray100, AppColors.gray50, AppColors.gray100],
              stops: const [0.1, 0.35, 0.7],
            ),
          ),
        );
      },
    );
  }
}

class AppPageSkeleton extends StatelessWidget {
  const AppPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          AppSkeletonLoader(height: 28),
          SizedBox(height: 12),
          AppSkeletonLoader(height: 14),
          SizedBox(height: 20),
          AppSkeletonLoader(height: 96),
          SizedBox(height: 12),
          AppSkeletonLoader(height: 96),
          SizedBox(height: 12),
          AppSkeletonLoader(height: 96),
        ],
      ),
    );
  }
}
