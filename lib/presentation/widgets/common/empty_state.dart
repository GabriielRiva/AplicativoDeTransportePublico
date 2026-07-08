import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Estado vazio padronizado para listas e telas sem conteúdo.
class EmptyState extends StatelessWidget {
  /// Cria o estado vazio com [icon], [title] e [message].
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  /// Ícone ilustrativo.
  final IconData icon;

  /// Título curto.
  final String title;

  /// Mensagem explicativa.
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 64, color: kTextSecondaryColor),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
