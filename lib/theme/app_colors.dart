import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dark theme foundations
  static const Color background = Color(0xFF0F0F0F);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF242424);
  static const Color surfaceBorder = Color(0xFF2E2E2E);

  // Text
  static const Color textPrimary = Color(0xFFE8E8E8);
  static const Color textSecondary = Color(0xFF9A9A9A);
  static const Color textTertiary = Color(0xFF5A5A5A);

  // Accent — Crimson
  static const Color accent = Color(0xFFDC143C);
  static const Color accentSoft = Color(0x33DC143C);
  static const Color accentHover = Color(0xFFE8273E);

  // Semantic
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // Score circle colors (1-5)
  static const Color score1 = Color(0xFFE74C3C);
  static const Color score2 = Color(0xFFE67E22);
  static const Color score3 = Color(0xFFF39C12);
  static const Color score4 = Color(0xFF27AE60);
  static const Color score5 = Color(0xFF2ECC71);

  static Color getScoreColor(int score) {
    switch (score) {
      case 1:
        return score1;
      case 2:
        return score2;
      case 3:
        return score3;
      case 4:
        return score4;
      case 5:
        return score5;
      default:
        return textTertiary;
    }
  }

  // ============================================
  // Status Colors
  // ============================================

  // Screening stage colors (blue progression)
  static const Color statusNew = Color(0xFFF1C40F);           // Yellow
  static const Color statusScreeningDone = Color(0xFF3498DB); // Blue
  static const Color statusCallUnattended = Color(0xFFE67E22); // Orange

  // Technical stage colors
  static const Color statusPendingScheduling = Color(0xFFF39C12); // Orange
  static const Color statusTechnical = Color(0xFFF1C40F);         // Yellow

  // Assignment stage color
  static const Color statusAssignment = Color(0xFF9B59B6);    // Purple

  // Final stage colors
  static const Color statusFinalReview = Color(0xFF00BCD4);   // Cyan
  static const Color statusOffer = Color(0xFF2ECC71);         // Green
  static const Color statusHired = Color(0xFFE8E8E8);         // White
  static const Color statusRejected = Color(0xFFE74C3C);      // Red

  // ============================================
  // Pipeline Stage Colors (for swimlane headers)
  // ============================================
  static const Color stageScreening = Color(0xFF3498DB);   // Blue
  static const Color stageScheduled = Color(0xFFF39C12);   // Orange
  static const Color stageTechnical = Color(0xFFF1C40F);   // Yellow
  static const Color stageAssignment = Color(0xFF9B59B6);  // Purple
  static const Color stageFinalReview = Color(0xFF2ECC71); // Green
}
