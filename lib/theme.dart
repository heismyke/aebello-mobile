import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The web app's design tokens (src/style.css), so both apps look the same.
abstract final class AppColors {
  static const ink = Color(0xFF18181B);
  static const muted = Color(0xFF71717A);
  static const subtle = Color(0xFF63646B);
  static const body = Color(0xFF4D4E56);
  static const eyebrow = Color(0xFF757580);
  static const paper = Color(0xFFFDFDFD);
  static const tile = Color(0xFFF7F7F8);
  static const surface = Color(0xFFEEF1F6);
  static const line = Color(0xFFE2E2E4);
  static const vibrant = Color(0xFFCCCCCC);
  static const tangerine = Color(0xFFF49C46);
  static const tangerineSoft = Color(0xFFFDF1E5);
  static const tangerineInk = Color(0xFF9A4A00);
  static const go = Color(0xFF15803D);
  static const goSoft = Color(0xFFE8F6EC);
  static const stop = Color(0xFFB42318);
  static const stopSoft = Color(0xFFFDECEA);
}

/// Headings use Bricolage Grotesque, like the website.
TextStyle display(double size, {Color color = Colors.black, FontWeight weight = FontWeight.w600}) =>
    GoogleFonts.bricolageGrotesque(fontSize: size, fontWeight: weight, color: color, height: 1.15);

ThemeData buildTheme() {
  // Avenir on the website; Nunito Sans is its free stand-in.
  final text = GoogleFonts.nunitoSansTextTheme().apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);
  const radius = BorderRadius.all(Radius.circular(14));
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.black,
      primary: Colors.black,
      onPrimary: Colors.white,
      secondary: AppColors.tangerine,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.paper,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: display(20),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size(0, 48),
        side: const BorderSide(color: AppColors.line),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Colors.black, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.tile,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
