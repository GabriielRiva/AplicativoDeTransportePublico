import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/update_metrics_controller.dart';
import '../../widgets/common/app_bottom_nav.dart';
import 'lines_page.dart';
import 'passenger_map_page.dart';
import 'passenger_profile_page.dart';

/// Shell do perfil do passageiro com Bottom Navigation (RF15/RF19):
/// Início (mapa), Linhas e Perfil, conforme UI_SPEC.
class PassengerHomePage extends ConsumerStatefulWidget {
  /// Cria a home do passageiro.
  const PassengerHomePage({super.key});

  @override
  ConsumerState<PassengerHomePage> createState() =>
      _PassengerHomePageState();
}

class _PassengerHomePageState extends ConsumerState<PassengerHomePage> {
  int _currentIndex = 0;

  static const List<Widget> _pages = <Widget>[
    PassengerMapPage(),
    LinesPage(),
    PassengerProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    // Mantém a medição do RNF05 rodando enquanto o passageiro usa o app,
    // sem redesenhar a tela a cada posição recebida.
    ref.listen<UpdateMetricsState>(
      updateMetricsProvider,
      (UpdateMetricsState? previous, UpdateMetricsState next) {},
    );
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (int index) => setState(() => _currentIndex = index),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Linhas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
