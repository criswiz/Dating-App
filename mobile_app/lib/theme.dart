import 'package:flutter/material.dart';

class AppColors {
  static const pink = Color(0xFFFF6B9D);
  static const purple = Color(0xFFB44FE8);
  static const gradient = LinearGradient(
    colors: [pink, purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientReversed = LinearGradient(
    colors: [purple, pink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: false,
      primaryColor: AppColors.pink,
      colorScheme: ColorScheme.light(
        primary: AppColors.pink,
        secondary: AppColors.purple,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F8F8),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: AppColors.pink,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 12,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pink,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.pink, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Colors.grey),
      ),
    );
  }
}
