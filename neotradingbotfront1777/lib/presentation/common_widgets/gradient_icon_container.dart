import 'package:flutter/material.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';

class GradientIconContainer extends StatelessWidget {
  final IconData icon;
  final double size;
  final double padding;
  final double borderRadius;
  final Gradient? gradient;

  const GradientIconContainer({
    required this.icon,
    super.key,
    this.size = 20,
    this.padding = 8,
    this.borderRadius = 8,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}
