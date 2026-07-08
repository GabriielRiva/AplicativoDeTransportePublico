import 'package:flutter/material.dart';

import '../../widgets/common/app_bottom_nav.dart';
import 'lines_page.dart';
import 'passenger_map_page.dart';
import 'passenger_profile_page.dart';

/// Shell do perfil do passageiro com Bottom Navigation (RF15/RF19):
/// Início (mapa), Linhas e Perfil, conforme UI_SPEC.
class PassengerHomePage extends StatefulWidget {
  /// Cria a home do passageiro.
  const PassengerHomePage({super.key});

  @override
  State<PassengerHomePage> createState() => _PassengerHomePageState();
}

class _PassengerHomePageState extends State<PassengerHomePage> {
  int _currentIndex = 0;

  static const List<Widget> _pages = <Widget>[
    PassengerMapPage(),
    LinesPage(),
    PassengerProfilePage(),
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
