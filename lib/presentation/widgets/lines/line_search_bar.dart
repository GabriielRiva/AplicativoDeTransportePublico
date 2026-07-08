import 'package:flutter/material.dart';

/// Campo de busca da tela de Linhas (UI_SPEC: Pesquisar).
class LineSearchBar extends StatelessWidget {
  /// Cria a barra de busca com o callback [onChanged].
  const LineSearchBar({required this.onChanged, super.key});

  /// Callback disparado a cada alteração do texto.
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: 'Pesquisar Linha e Trajetos',
          prefixIcon: Icon(Icons.search),
        ),
      ),
    );
  }
}
