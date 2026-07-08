import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/schedule.dart';

/// Item de horário de saída de uma linha (RF10).
class ScheduleTile extends StatelessWidget {
  /// Cria o item do horário [schedule].
  const ScheduleTile({required this.schedule, super.key});

  /// Horário exibido.
  final Schedule schedule;

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
    );
  }
}
