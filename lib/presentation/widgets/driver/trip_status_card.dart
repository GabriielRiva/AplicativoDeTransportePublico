import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/enums/driver_status.dart';

/// Card "Status do Trajeto" da tela do motorista (RF14).
class TripStatusCard extends StatelessWidget {
  /// Cria o card com o [status] atual.
  const TripStatusCard({required this.status, super.key});

  /// Status atual do trajeto.
  final DriverStatus status;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            const Text('Status do Trajeto:', style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Text(status.label, style: AppTextStyles.title),
          ],
        ),
      ),
    );
  }
}
