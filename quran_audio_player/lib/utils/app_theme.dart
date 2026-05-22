import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── WARM BROWN PALETTE ───────────────────────────────────────────────────
  static const Color background    = Color(0xFF1A0C07); // Espresso dark
  static const Color surfaceDeep   = Color(0xFF2D1B14); // Dark coffee
  static const Color surface       = Color(0xFF3E2C23); // Coffee brown
  static const Color surfaceCard   = Color(0xFF4A3530); // Card warm brown
  static const Color accentGold    = Color(0xFFC5A059); // Warm gold
  static const Color goldLight     = Color(0xFFD4AF37); // Bright gold
  static const Color goldDim       = Color(0xFF9A7A3A); // Dimmer gold
  static const Color primaryText   = Color(0xFFFDD8D0); // Warm cream
  static const Color textSecondary = Color(0xFFAA8870); // Muted warm brown
  static const Color textMuted     = Color(0xFF7A5A4A); // Very muted
  static const Color errorColor    = Color(0xFFFFB4AB); // Error red
  static const Color navyHeader    = Color(0xFF1F0F09); // Dark espresso header

  // ─── ALIASES (backward compat) ────────────────────────────────────────────
  static const Color bg            = background;
  static const Color primary       = accentGold;
  static const Color accent        = accentGold;
  static const Color textPrimary   = primaryText;
  static const Color error         = errorColor;
  static const Color navBlue       = accentGold;   // was blue, now gold
  static const Color surfaceCoffee = surface;
  static const Color warmBrown     = surfaceCard;
  static const Color emerald       = accentGold;   // was emerald, now gold
  static const Color emeraldLight  = goldLight;
  static const Color divider       = Color(0xFF5A3A2A);

  // ─── ASSET URLS ───────────────────────────────────────────────────────────
  static const String heroImage  = "https://lh3.googleusercontent.com/aida-public/AB6AXuBek5ZZ_sZuyZT7z8QmQC9oJdsFc5c8qZU_VNxrWCqG1eKlHhd5vu_fQofv0Wy5ToI5jIwiH-o_fJHgBay2bSaaPVrHI65jUPstlPKSkGSYudG0chQejh11WYWVCsAe7f4Xz4hG7NydYqVAgVDCJgFTpep1OzMfy03kfDWR1Wn2h4n7NS78kpIiAK31twWwoU-lDzfjGr9rCWR4hyCRjCkZhD3dRBEMYeySQMFVZJEOkdzx9ZC0p6Zd7TlZIlLkNHjE3zWbKSX_Pnn5";
  static const String playerArt  = "https://lh3.googleusercontent.com/aida-public/AB6AXuCSS8fCn524K5nW792o6j2VDxVnSg5oO4JcZf80nsvmyKXLRzvtrk7YMFtLU701xQCeAPlKjwkQIf4KRFvaWCFRTKmEKNTzdGbOmQdX1iUq9DzWOSg02WJCAN0DJFYwYvbVn_JL7mKHNu4aXMkbonU4c7orMKi4hf8eRcQu3MMiY9NRaxMZAjof-iFlhk91nkA6BvQ-t9HpPH8TBrK2XjujYnR-geP2BmFXmHGcGjupNbJ9M6BJ5-1-vNOK53lNWFsE_kw-MqdwqZzC";

  // ─── GRADIENTS ────────────────────────────────────────────────────────────
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFC5A059)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF2D1B14), Color(0xFF604403)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF4A3530), Color(0xFF3A2520)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── GLOWS & SHADOWS ─────────────────────────────────────────────────────
  static List<BoxShadow> goldGlow({double opacity = 0.3, double blur = 20}) => [
    BoxShadow(
      color: accentGold.withValues(alpha: opacity),
      blurRadius: blur,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // ─── DECORATIONS ─────────────────────────────────────────────────────────
  static BoxDecoration cardDecoration({Color? color, double radius = 16}) =>
      BoxDecoration(
        color: color ?? surfaceCard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.06), width: 1),
        boxShadow: cardShadow,
      );

  static BoxDecoration glassDecoration({double radius = 20}) => BoxDecoration(
        color: surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
            color: accentGold.withValues(alpha: 0.12), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3), blurRadius: 20),
        ],
      );

  // ─── LIGHT PALETTE ────────────────────────────────────────────────────────
  static const Color _lBg          = Color(0xFFFDF7F0);
  static const Color _lSurface     = Color(0xFFEEDEC8);
  static const Color _lCard        = Color(0xFFE6D1B0);
  static const Color _lAppBar      = Color(0xFF3E2C23);
  static const Color _lText        = Color(0xFF2D1B0E);
  static const Color _lTextSec     = Color(0xFF7A5840);
  static const Color _lDivider     = Color(0xFFD6C0A0);

  // ─── THEME DATA (DARK) ────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        primaryColor: accentGold,
        colorScheme: const ColorScheme.dark(
          primary: accentGold,
          secondary: accentGold,
          surface: surface,
          error: errorColor,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.dark().textTheme,
        ).apply(bodyColor: primaryText, displayColor: Colors.white),
        appBarTheme: AppBarTheme(
          backgroundColor: navyHeader,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: navyHeader,
          selectedItemColor: accentGold,
          unselectedItemColor: Colors.white30,
          type: BottomNavigationBarType.fixed,
        ),
        cardTheme: CardThemeData(
          color: surfaceCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.10)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.10)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: accentGold, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: errorColor),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: errorColor, width: 1.5),
          ),
          labelStyle: const TextStyle(color: textSecondary),
          prefixIconColor: textSecondary,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentGold,
            foregroundColor: Colors.black,
            elevation: 0,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: accentGold),
        ),
        dividerColor: divider,
      );

  // ─── THEME DATA (LIGHT) ───────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: _lBg,
        primaryColor: accentGold,
        colorScheme: ColorScheme.light(
          primary: accentGold,
          secondary: accentGold,
          surface: _lSurface,
          error: Colors.red.shade700,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.light().textTheme,
        ).apply(bodyColor: _lText, displayColor: _lText),
        appBarTheme: AppBarTheme(
          backgroundColor: _lAppBar,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: _lAppBar,
          selectedItemColor: accentGold,
          unselectedItemColor: Colors.white38,
          type: BottomNavigationBarType.fixed,
        ),
        cardTheme: CardThemeData(
          color: _lCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _lSurface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: accentGold, width: 1.5),
          ),
          labelStyle: TextStyle(color: _lTextSec),
          prefixIconColor: _lTextSec,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentGold,
            foregroundColor: Colors.black,
            elevation: 0,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: accentGold),
        ),
        dividerColor: _lDivider,
      );
}