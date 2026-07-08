import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'service_providers.dart';

/// Stream do estado de conectividade do dispositivo.
///
/// Usada para exibir aviso de "sem conexão" e bloquear operações
/// críticas quando offline (PROJECT_RULES: sempre validar internet).
final StreamProvider<bool> connectivityProvider =
    StreamProvider<bool>((Ref ref) {
  return ref.watch(networkInfoProvider).onStatusChange;
});
