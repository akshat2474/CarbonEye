import 'package:flutter/material.dart';
import 'package:carboneye/utils/constants.dart';

class NeuCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const NeuCard({
    super.key,
    required this.child,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.all(16.0),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? kCardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
        border: Border.all(
          color: kSecondaryTextColor.withOpacity(0.1),
          width: 1.0,
        ),
      ),
      child: child,
    );
  }
}