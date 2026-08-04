import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warna diambil persis dari Figma (fileKey V9uSigAtrTjY8iFaAZisto).
/// Jangan hardcode hex baru di widget — tambahin di sini biar satu sumber.
class AppColors {
  AppColors._();

  static const background = Color(0xFFFBF7F4);
  static const primary = Color(0xFFC8102E);
  static const textPrimary = Color(0xFF1A1414);
  static const textLabel = Color(0xFF3E3434);
  static const textMuted = Color(0xFF6B5E5E);
  static const textPlaceholder = Color(0xFF9CA3AF);

  /// Dipakai buat kartu ilustrasi (layer abu di belakang) & teks tab nonaktif.
  static const neutralMuted = Color(0xFFA29694);

  static const inputBorder = Color(0xFFE6DCD5);
  static const tabInactiveBg = Color(0xFFF3ECE7);
  static const success = Color(0xFF2F8F5B);

  static const buttonDisabledBg = Color(0xFFE6DCD5);
  static const buttonDisabledText = Color(0xFFA29694);

  static const cardDark = Color(0xFF1A1414);
}

/// Font Figma: Plus Jakarta Sans. Dipasang via google_fonts biar gak perlu
/// bundling file font manual.
class AppText {
  AppText._();

  static final TextStyle _base = GoogleFonts.plusJakartaSans();

  static TextStyle label = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textLabel,
  );

  static TextStyle inputText = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle placeholder = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPlaceholder,
  );

  static TextStyle helper = _base.copyWith(
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  static TextStyle tab = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  static TextStyle button = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static TextStyle headline = _base.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle statLabel = _base.copyWith(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    color: Colors.white.withValues(alpha: 0.5),
    letterSpacing: 1.4,
  );

  static TextStyle statValue = _base.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static TextStyle statValueSmall = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static TextStyle statLabelSmall = _base.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: Colors.white.withValues(alpha: 0.5),
  );

  static TextStyle chip = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static TextStyle navLabel = _base.copyWith(
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
  );
}
