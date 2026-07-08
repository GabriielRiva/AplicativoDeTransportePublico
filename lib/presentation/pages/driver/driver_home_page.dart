import 'package:flutter/material.dart';

import '../../widgets/common/app_bottom_nav.dart';
import '../passenger/lines_page.dart';
import 'driver_profile_page.dart';
import 'driver_trip_page.dart';

/// Shell do perfil do motorista com Bottom Navigation (RF14/RF19):
/// Trajeto, Linhas e Perfil, conforme wireframes do TCC.
///
/// A tela de Linhas é reutilizada do fluxo do passageiro
/// (PROJECT_RULES: utilizar Widgets reutilizáveis).
class DriverHomePage extends StatefulWidget {
  /// Cria a home do motorista.
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  // Abre na aba Perfil, tela principal do motorista (Figura 9 do TCC).
  int _currentIndex = 2;

  static const List<Widget> _pages = <Widget>[
    DriverTripPage(),
    LinesPage(),
    DriverProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (int index) => setState(() => _currentIndex = index),
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
