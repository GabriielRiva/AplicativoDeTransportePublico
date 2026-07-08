import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/firebase_initializer.dart';

/// Ponto de entrada do TranCity: inicializa o Firebase e sobe o app
/// dentro do ProviderScope do Riverpod.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseInitializer.initialize();
  runApp(const ProviderScope(child: TranCityApp()));
}
