import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/stop.dart';

/// Item de ponto de parada na rota detalhada (RF09).
class StopTile extends StatelessWidget {
  /// Cria o item da parada [stop].
  const StopTile({required this.stop, this.subtitle, super.key});

  /// Parada exibida.
  final Stop stop;

  /// Texto auxiliar (ex.: tempo estimado desde o ponto anterior).
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: kPrimaryColor,
        child: Text(
          '${stop.order}',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
      title: Text(stop.name, style: AppTextStyles.body),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: AppTextStyles.caption),
    );
  }
}
