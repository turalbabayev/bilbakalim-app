import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Mor tonları (referans görsele göre)#520a8b
  static const Color primaryColor = Color(0xFF520A8B);
  static const Color secondaryColor = Color(0xFF181C5F);
  static const Color accentColor = Color(0xFF181C5F);
  static const Color tertiaryColor = Color(0xFF181C5F);
  static const Color backgroundColor = Color(0xFFF5F5F5); // Kırık beyaz
  static const Color textColor = Color(0xFF1A1A1A); // Koyu metin rengi
  static const Color backgroundColorFistik = Color(0xFFF3FF6C);
  
  // TabBar renkleri
  static const Color tabBarBackground = Color(0xFFE8E8E8); // Hafif gri arkaplan
  static const Color tabBarIndicator = Color(0xFF9E9E9E); // Orta gri indikatör
  static const Color tabBarUnselected = Color(0xFF757575); // Seçili olmayan tab rengi
  
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF181C5F), // Üst lacivert
      Color(0xFF181C5F), // Alt lacivert
    ],
  );

  // Header için gradient
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF181C5F), // Koyu lacivert
      Color(0xFF181C5F), // Aynı renk - düz bir görünüm için
    ],
  );

  // Text stilleri
  static TextStyle titleStyle = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
  );
  
  static TextStyle subtitleStyle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textColor,
  );
  
  static TextStyle bodyStyle = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textColor,
  );
  
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 4,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  // Kart stilleri
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: primaryColor.withOpacity(0.1),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );
} 