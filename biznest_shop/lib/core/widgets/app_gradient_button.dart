import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppGradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Size? minimumSize;
  final bool enabled;

  const AppGradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderRadius = 12,
    this.padding,
    this.minimumSize,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || !enabled;

    return Opacity(
      opacity: disabled ? 0.65 : 1,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary600.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: padding,
            minimumSize: minimumSize,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
