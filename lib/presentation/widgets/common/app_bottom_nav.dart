import 'package:flutter/material.dart';

/// Barra de navegação inferior padronizada (RF19).
class AppBottomNav extends StatelessWidget {
  /// Cria a barra com os [items] e o [currentIndex] ativo.
  const AppBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    super.key,
  });

  /// Índice da aba ativa.
  final int currentIndex;

  /// Callback de troca de aba.
  final ValueChanged<int> onTap;

  /// Itens da navegação.
  final List<BottomNavigationBarItem> items;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: items,
    );
  }
}
