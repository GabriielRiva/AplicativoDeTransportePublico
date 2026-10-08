import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/schedule.dart';

/// Item de horário de saída de uma linha (RF10).
class ScheduleTile extends StatelessWidget {
  /// Cria o item do horário [schedule].
  const ScheduleTile({required this.schedule, this.onTap, super.key});

  /// Horário exibido.
  final Schedule schedule;

  /// Ação ao tocar no horário (ex.: ver a previsão em cada ponto).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.schedule),
      title: Text(schedule.departureTime, style: AppTextStyles.title),
      subtitle: Text(
        Formatters.weekdayName(schedule.weekday),
        style: AppTextStyles.caption,
      ),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
