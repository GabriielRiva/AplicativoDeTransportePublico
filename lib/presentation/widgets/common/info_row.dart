import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';

/// Linha de informação com ícone, rótulo e valor em destaque,
/// reutilizada nos cards de rota e de trajeto.
class InfoRow extends StatelessWidget {
  /// Cria a linha de informação.
  const InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  /// Ícone à esquerda.
  final IconData icon;

  /// Rótulo do dado (ex.: "Distância Total:").
  final String label;

  /// Valor em negrito.
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.body),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}