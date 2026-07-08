import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/line.dart';

/// Card de uma linha na listagem (RF08).
class LineCard extends StatelessWidget {
  /// Cria o card da [line] com ação [onTap].
  const LineCard({required this.line, required this.onTap, super.key});

  /// Linha exibida.
  final Line line;

  /// Ação ao tocar no card.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color lineColor = colorFromHex(line.color);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: lineColor.withValues(alpha: 0.15),
          child: Icon(Icons.directions_bus, color: lineColor),
        ),
        title: Text(line.displayName, style: AppTextStyles.title),
        subtitle: Text(
          '${line.description} · ${Formatters.distanceKm(line.distance)}',
          style: AppTextStyles.caption,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
