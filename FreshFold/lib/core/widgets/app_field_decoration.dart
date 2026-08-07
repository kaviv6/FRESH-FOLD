import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Shared `InputDecoration` for the rounded, thin-bordered text fields used
/// on every form screen (login, signup, business enquiry, ...).
InputDecoration appFieldDecoration({required String hint}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: 1.5),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: AppText.body(AppColors.muted350),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: border(AppColors.border),
    enabledBorder: border(AppColors.border),
    focusedBorder: border(AppColors.teal),
    errorBorder: border(AppColors.redText),
    focusedErrorBorder: border(AppColors.redText),
  );
}
