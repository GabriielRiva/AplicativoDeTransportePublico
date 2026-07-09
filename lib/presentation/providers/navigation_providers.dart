import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Índice da aba ativa na Bottom Navigation do motorista.
/// Abre na aba Perfil (índice 2), tela principal do motorista.
final StateProvider<int> driverNavIndexProvider =
    StateProvider<int>((Ref ref) => 2);