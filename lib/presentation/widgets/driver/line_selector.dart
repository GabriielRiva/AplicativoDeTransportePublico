import 'package:flutter/material.dart';

import '../../../domain/entities/line.dart';

/// Seletor de linha da tela do motorista (UI_SPEC: Selecionar Linha).
class LineSelector extends StatelessWidget {
  /// Cria o seletor com as [lines] disponíveis.
  const LineSelector({
    required this.lines,
    required this.selected,
    required this.onChanged,
    required this.enabled,
    super.key,
  });

  /// Linhas disponíveis para seleção.
  final List<Line> lines;

  /// Linha atualmente selecionada.
  final Line? selected;

  /// Callback de seleção.
  final ValueChanged<Line> onChanged;

  /// Desabilitado durante um trajeto ativo.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Line>(
      initialValue: selected,
      isExpanded: true,
      decoration: const InputDecoration(
        hintText: 'Selecionar Linha',
        prefixIcon: Icon(Icons.alt_route),
      ),
      items: lines
          .map(
            (Line line) => DropdownMenuItem<Line>(
              value: line,
              child: Text(line.displayName, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: enabled
          ? (Line? line) {
              if (line != null) onChanged(line);
            }
          : null,
    );
  }
}
