import 'package:flutter/material.dart';

/// Azul principal da identidade visual (logo e botões).
const Color kPrimaryColor = Color(0xFF4A9EBF);

/// Variante escura do azul principal.
const Color kPrimaryDarkColor = Color(0xFF35708A);

/// Cor de fundo padrão das telas.
const Color kBackgroundColor = Color(0xFFF7F6F4);

/// Cor das superfícies elevadas (cards, sheets).
const Color kSurfaceColor = Colors.white;

/// Verde do botão "Iniciar Trajeto" e dos marcadores de ônibus ativos.
const Color kSuccessColor = Color(0xFF2E9E4F);

/// Vermelho do botão "Encerrar Trajeto" e mensagens de erro.
const Color kErrorColor = Color(0xFFE5484D);

/// Cor de textos primários.
const Color kTextPrimaryColor = Color(0xFF1E1E1E);

/// Cor de textos secundários e placeholders.
const Color kTextSecondaryColor = Color(0xFF6B6B6B);

/// Converte uma cor hexadecimal ("#4A9EBF") em [Color], com fallback
/// para a cor primária quando o valor é inválido.
Color colorFromHex(String hex, {Color fallback = kPrimaryColor}) {
  final String cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length != 6) return fallback;
  final int? value = int.tryParse(cleaned, radix: 16);
  if (value == null) return fallback;
  return Color(0xFF000000 + value);
}
