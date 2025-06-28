import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: const Color.fromARGB(255, 0, 0, 0), // 🔥 Change Primary Color
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0), // 🔥 Change Top Bar Color
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white, // 🔥 Title color
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(
        color: Colors.white, // 🔥 Icon color
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white, // Bottom bar color
      selectedItemColor: Colors.deepPurple, // Selected icon color
      unselectedItemColor: Colors.grey, // Unselected icon color
    ),
  );
}
