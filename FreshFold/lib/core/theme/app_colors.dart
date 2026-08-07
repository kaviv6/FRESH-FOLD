import 'package:flutter/material.dart';

/// Palette converted from the Claude Design source (`oklch(...)` tokens) to
/// sRGB hex. Names follow the role each color plays in the design, not the
/// oklch coordinates, so usage sites stay readable.
class AppColors {
  AppColors._();

  // Neutrals / ink scale (oklch(_% 0.02 240) family)
  static const ink900 = Color(0xFF0E171E);
  static const ink800 = Color(0xFF19232A);
  static const ink700 = Color(0xFF252F37);
  static const ink600 = Color(0xFF313C44);
  static const ink500 = Color(0xFF3E4952);
  static const ink400 = Color(0xFF4C575F);
  static const muted500 = Color(0xFF545F68);
  static const muted450 = Color(0xFF59656E);
  static const muted400 = Color(0xFF67737C);
  static const muted350 = Color(0xFF76828B);
  static const muted300 = Color(0xFF8A9095);

  static const border = Color(0xFFDBDFE2);
  static const borderLight = Color(0xFFE1E5E8);
  static const chipNeutralBg = Color(0xFFE3E9ED);
  static const surfaceMuted = Color(0xFFE8ECEF);
  static const bgApp = Color(0xFFEFF2F4);
  static const bgScreen = Color(0xFFF3F5F7);
  static const bgSoft = Color(0xFFF6F9FB);
  static const white = Color(0xFFFFFFFF);

  // Brand teal — customer role
  static const teal = Color(0xFF00868C);
  static const tealDeep = Color(0xFF005A64);
  static const tealMid = Color(0xFF007277);
  static const tealText = Color(0xFF00666D);
  static const tealTextStrong = Color(0xFF00676F);
  static const tealChipBg = Color(0xFFD2EEF0);
  static const tealChipBgSoft = Color(0xFFD5F2F3);
  static const tealChipBgStrong = Color(0xFFC5F6F8);

  // Coral / amber — rider role + accent CTAs
  static const coral = Color(0xFFC9690C);
  static const coralLight = Color(0xFFDD8736);
  static const coralDeep = Color(0xFFB2511E);
  static const coralText = Color(0xFF873E00);
  static const coralChipBg = Color(0xFFFFE3B1);
  static const coralChipText = Color(0xFF914700);

  // Purple — admin role
  static const purple = Color(0xFF584FA3);
  static const purpleChipBg = Color(0xFFE1E0FF);
  static const purpleChipBgSoft = Color(0xFFE4E3FF);

  // Blue — "scheduled" status
  static const blueChipBg = Color(0xFFCBEDFF);
  static const blueChipText = Color(0xFF005B9A);

  // Green — success / delivered
  static const greenChipBg = Color(0xFFC3F9C3);
  static const greenChipText = Color(0xFF146720);

  // Red — cancelled / destructive
  static const redChipBg = Color(0xFFFFDCD7);
  static const redChipBgSoft = Color(0xFFFFE0DA);
  static const redChipText = Color(0xFFA92227);
  static const redText = Color(0xFFA83634);

  /// Maps a `laundry.order` / `laundry.pickup.request` state string to the
  /// (background, foreground) chip colors used throughout the app.
  static (Color bg, Color fg) statusChip(String state) {
    switch (state) {
      case 'draft':
        return (chipNeutralBg, muted500);
      case 'order':
      case 'scheduled':
        return (blueChipBg, blueChipText);
      case 'picked':
        return (coralChipBg, coralChipText);
      case 'invoiced':
        return (tealChipBgStrong, tealTextStrong);
      case 'delivered':
        return (greenChipBg, greenChipText);
      case 'cancel':
      case 'cancelled':
        return (redChipBg, redChipText);
      default:
        return (chipNeutralBg, muted500);
    }
  }
}
