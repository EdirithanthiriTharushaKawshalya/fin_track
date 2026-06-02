import 'package:flutter/material.dart';
import 'dart:ui';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;

    return Stack(
      children: [
        // Base Background
        Container(
          color: theme.scaffoldBackgroundColor,
        ),
        
        // Top Right Blob - More vibrant
        Positioned(
          top: -120,
          right: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(isDark ? 0.12 : 0.15),
            ),
          ),
        ),

        // Bottom Left Blob - More vibrant
        Positioned(
          bottom: -150,
          left: -100,
          child: Container(
            width: 450,
            height: 450,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: secondaryColor.withOpacity(isDark ? 0.12 : 0.15),
            ),
          ),
        ),

        // Center Right Blob for additional color
        Positioned(
          top: MediaQuery.of(context).size.height * 0.4,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: secondaryColor.withOpacity(isDark ? 0.08 : 0.1),
            ),
          ),
        ),

        // Blur effect - slightly reduced to let colors shine through more
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),

        // The actual content
        child,
      ],
    );
  }
}
