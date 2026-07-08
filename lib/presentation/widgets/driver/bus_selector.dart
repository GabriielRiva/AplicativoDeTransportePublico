import 'package:flutter/material.dart';

import '../../../domain/entities/bus.dart';

/// Seletor de ônibus da tela do motorista (UI_SPEC: Selecionar Ônibus).
class BusSelector extends StatelessWidget {
  /// Cria o seletor com os [buses] da linha selecionada.
  const BusSelector({
    required this.buses,
    required this.selected,
    required this.onChanged,
    required this.enabled,
    super.key,
  });

  /// Ônibus disponíveis para seleção.
  final List<Bus> buses;

  /// Ônibus atualmente selecionado.
  final Bus? selected;

  /// Callback de seleção.
  final ValueChanged<Bus> onChanged;

  /// Desabilitado durante um trajeto ativo ou sem linha selecionada.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Bus>(
      initialValue: selected,
      isExpanded: true,
      decoration: const InputDecoration(
        hintText: 'Selecionar Ônibus',
        prefixIcon: Icon(Icons.directions_bus),
      ),
      items: buses
          .map(
            (Bus bus) => DropdownMenuItem<Bus>(
              value: bus,
              child: Text(
                'Ônibus #${bus.number} · ${bus.plate}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: enabled
          ? (Bus? bus) {
              if (bus != null) onChanged(bus);
            }
          : null,
    );
  }
}
