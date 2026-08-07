import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Text styles mirroring the Inter weights used in the design source
/// (400/500/600/700/800).
class AppText {
  AppText._();

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    Color color = AppColors.ink900,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle display(Color color) =>
      _base(size: 26, weight: FontWeight.w800, color: color, letterSpacing: -0.2);

  static TextStyle h1(Color color) =>
      _base(size: 22, weight: FontWeight.w800, color: color);

  static TextStyle h2(Color color) =>
      _base(size: 20, weight: FontWeight.w800, color: color);

  static TextStyle title(Color color) =>
      _base(size: 18, weight: FontWeight.w800, color: color);

  static TextStyle bodyBold(Color color) =>
      _base(size: 14, weight: FontWeight.w700, color: color);

  static TextStyle body(Color color) =>
      _base(size: 14, weight: FontWeight.w400, color: color, height: 1.4);

  static TextStyle bodySmallBold(Color color) =>
      _base(size: 13, weight: FontWeight.w700, color: color);

  static TextStyle bodySmall(Color color) =>
      _base(size: 13, weight: FontWeight.w400, color: color, height: 1.4);

  static TextStyle caption(Color color) =>
      _base(size: 12, weight: FontWeight.w500, color: color);

  static TextStyle captionBold(Color color) =>
      _base(size: 12, weight: FontWeight.w700, color: color);

  static TextStyle micro(Color color) =>
      _base(size: 10.5, weight: FontWeight.w600, color: color);

  static TextStyle microBold(Color color) =>
      _base(size: 10.5, weight: FontWeight.w700, color: color);

  static TextStyle button(Color color) =>
      _base(size: 15, weight: FontWeight.w700, color: color);

  static TextStyle eyebrow(Color color) => _base(
        size: 12,
        weight: FontWeight.w700,
        color: color,
        letterSpacing: 0.6,
      );
}
