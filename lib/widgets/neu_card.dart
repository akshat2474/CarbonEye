import 'package:flutter/material.dart';
import 'package:carboneye/utils/constants.dart';

class NeuCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final bool enableShadow; // Add this parameter

  const NeuCard({
    super.key,
    required this.child,
    this.borderRadius = 15.0,
    this.padding = const EdgeInsets.all(12.0),
    this.color,
    this.enableShadow = false, // Default to no shadow
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? kCardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: enableShadow ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(4, 4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: kCardColor.withOpacity(0.7),
            offset: const Offset(-4, -4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ] : null,
      ),
      child: child,
    );
  }
}
