import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData pharmacyTheme = ThemeData(
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: const Color(0xFF2E7D32),
    onPrimary: Colors.white,
    secondary: const Color.fromARGB(255, 243, 175, 3),
    onSecondary: Colors.black,
    error: const Color(0xFFD32F2F),
    onError: Colors.white,
    surface: const Color(0xFFF3F8F2),
    onSurface: Colors.black,
  ),
  scaffoldBackgroundColor: const Color(0xFFF3F8F2),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF2E7D32),
    foregroundColor: Colors.white,
    elevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  ),
  cardColor: Colors.white,
  cardTheme: const CardThemeData(
    color: Colors.white,
    elevation: 1,
    surfaceTintColor: Colors.transparent,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  ),
  textTheme: TextTheme(
    headlineMedium: GoogleFonts.poppins(
      fontWeight: FontWeight.bold,
      color: const Color(0xFF2E7D32),
    ),
    bodyMedium: GoogleFonts.roboto(color: const Color(0xFF212121)),
    bodySmall: GoogleFonts.roboto(color: const Color(0xFF757575)),
  ),
);
