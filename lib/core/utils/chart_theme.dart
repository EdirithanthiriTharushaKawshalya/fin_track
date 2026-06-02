import 'package:flutter/material.dart';

class ChartTheme {
  // Base colors matching the reference image's vibrant yet soft tones
  static const Color expenseBaseColor = Color(0xFFFF5A66); // Premium coral/pinkish red
  static const Color incomeBaseColor = Color(0xFF03DAC6); // Premium teal/mint

  /// Generates a monochromatic color for a given slice index based on the size/order index.
  /// Index 0 is the base color.
  /// Index 1 is the lightest.
  /// Subsequent indices get progressively darker.
  static Color getMonochromaticColor(int index, int totalCount, String type) {
    final Color baseColor = type == 'expense' ? expenseBaseColor : incomeBaseColor;
    if (totalCount <= 1) return baseColor;
    if (index == 0) return baseColor;

    final hsl = HSLColor.fromColor(baseColor);
    
    double lightness;
    if (totalCount == 2) {
      lightness = 0.82;
    } else {
      final double ratio = (index - 1) / (totalCount - 2);
      lightness = 0.90 - (ratio * 0.22); // range from 0.90 (lightest) down to 0.68
    }

    final double saturation = hsl.saturation * (0.6 + (1.0 - lightness) * 1.0).clamp(0.4, 1.0);

    return HSLColor.fromAHSL(
      1.0,
      hsl.hue,
      saturation,
      lightness.clamp(0.0, 1.0),
    ).toColor();
  }

  /// Calculates a highly readable text color that matches the slice's tone
  /// but has sufficient contrast for the current brightness mode.
  static Color getLabelTextColor(Color sliceColor, bool isDark) {
    final hsl = HSLColor.fromColor(sliceColor);
    if (isDark) {
      // In dark mode, ensure lightness is high enough for contrast
      return HSLColor.fromAHSL(1.0, hsl.hue, hsl.saturation, hsl.lightness.clamp(0.80, 1.0)).toColor();
    } else {
      // In light mode, ensure lightness is low enough for contrast
      return HSLColor.fromAHSL(1.0, hsl.hue, hsl.saturation, hsl.lightness.clamp(0.0, 0.40)).toColor();
    }
  }
}
