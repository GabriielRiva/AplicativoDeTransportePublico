import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/bus.dart';

/// Card "Informações do Veículo" da tela do motorista (RF14).
class VehicleInfoCard extends StatelessWidget {
  /// Cria o card com os dados do [bus] selecionado.
  const VehicleInfoCard({required this.bus, super.key});

  /// Ônibus selecionado (nulo exibe orientação de seleção).
  final Bus? bus;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            const Text('Informações do Veículo', style: AppTextStyles.title),
            const SizedBox(height: 12),
            if (bus == null)
              const Text(
                'Selecione uma linha e um ônibus para ver os detalhes.',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              )
            else
              Row(
                children: <Widget>[
                  const CircleAvatar(
                    backgroundColor: kPrimaryColor,
                    child:
                        Icon(Icons.directions_bus, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                      Text(
                          'Ônibus: #${bus!.number}',
                          style: AppTextStyles.body,
                        ),
                        Text(
                          'Modelo: ${bus!.model}',
                          style: AppTextStyles.body,
                        ),
                        Text(
                          'Placa: ${bus!.plate}',
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
