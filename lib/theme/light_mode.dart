import 'package:flutter/material.dart';
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
    surface: const Color.fromARGB(255, 201, 228, 203),
    onSurface: Colors.black,
  ),
  scaffoldBackgroundColor:const Color.fromARGB(255, 201, 228, 203),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF2E7D32),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  ),
  textTheme: TextTheme(
    headlineMedium: GoogleFonts.poppins(
      fontWeight: FontWeight.bold,
      color: const Color(0xFF2E7D32),
    ),
    bodyMedium: GoogleFonts.roboto(
      color: const Color(0xFF212121),
    ),
    bodySmall: GoogleFonts.roboto(
      color: const Color(0xFF757575),
    ),
  ),
  cardColor: const Color.fromARGB(255, 243, 175, 3), 
);
