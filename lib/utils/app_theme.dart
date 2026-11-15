import 'package:flutter/material.dart';

/// Definição centralizada dos temas Claro e Escuro do Prova Certa (AvaliaPro).
///
/// O tema escuro utiliza uma paleta de alto contraste baseada em tons Slate,
/// garantindo excelente legibilidade e preservando a identidade visual roxa/índigo.
class AppTheme {
  // Cores da Identidade Visual
  static const Color primaryColor = Color(0xFF6542ED);
  static const Color primaryLight = Color(0xFFF0EDFF);
  static const Color primaryDark = Color(0xFF8C7BFA);

  // Paleta Claro
  static const Color lightBackground = Color(0xFFF5F7FB);
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = Color(0xFF101827);
  static const Color lightTextSecondary = Color(0xFF7988A0);
  static const Color lightDivider = Color(0xFFE4E9F1);

  // Paleta Escuro (Slate Design System de alto contraste)
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkDivider = Color(0xFF334155);

  /// Tema claro da aplicação
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,
    cardColor: lightSurface,
    dividerColor: lightDivider,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      surface: lightSurface,
      onSurface: lightTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightSurface,
      foregroundColor: lightTextPrimary,
      surfaceTintColor: lightSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: lightTextPrimary),
      titleTextStyle: TextStyle(
        color: lightTextPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: lightSurface,
      surfaceTintColor: lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
  );

  /// Tema escuro da aplicação
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    cardColor: darkCard,
    dividerColor: darkDivider,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryDark,
      brightness: Brightness.dark,
      surface: darkSurface,
      onSurface: darkTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: darkTextPrimary,
      surfaceTintColor: darkSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: darkTextPrimary),
      titleTextStyle: TextStyle(
        color: darkTextPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: darkSurface,
      surfaceTintColor: darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
  );
}
