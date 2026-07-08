import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Estilos de texto reutilizáveis do aplicativo.
abstract final class AppTextStyles {
  /// Título grande (logo/cabeçalhos de tela).
  static const TextStyle headline = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: kPrimaryColor,
  );

  /// Título de seções e cards.
  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: kTextPrimaryColor,
  );

  /// Texto padrão do corpo das telas.
  static const TextStyle body = TextStyle(
    fontSize: 15,
    color: kTextPrimaryColor,
  );

  /// Texto auxiliar (legendas, dicas, placeholders).
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    color: kTextSecondaryColor,
  );

  /// Texto de botões.
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
