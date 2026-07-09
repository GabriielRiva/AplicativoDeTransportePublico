import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/navigation_providers.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../passenger/lines_page.dart';
import 'driver_profile_page.dart';
import 'driver_trip_page.dart';

/// Shell do perfil do motorista com Bottom Navigation (RF14/RF19):
/// Trajeto, Linhas e Perfil, conforme wireframes do TCC.
///
/// A tela de Linhas é reutilizada do fluxo do passageiro
/// (PROJECT_RULES: utilizar Widgets reutilizáveis).
class DriverHomePage extends ConsumerWidget {
  /// Cria a home do motorista.
  const DriverHomePage({super.key});

  static const List<Widget> _pages = <Widget>[
    DriverTripPage(),
    LinesPage(),
    DriverProfilePage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int currentIndex = ref.watch(driverNavIndexProvider);

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _pages),
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        onTap: (int index) =>
            ref.read(driverNavIndexProvider.notifier).state = index,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.route_outlined),
            label: 'Trajeto',
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