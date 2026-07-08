import 'package:firebase_core/firebase_core.dart';

import '../utils/app_logger.dart';

/// Inicialização do Firebase.
///
/// No Android a configuração é lida automaticamente do arquivo
/// `android/app/google-services.json`, dispensando o firebase_options.dart.
abstract final class FirebaseInitializer {
  /// Inicializa o app padrão do Firebase antes do runApp.
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      AppLogger.info('Firebase inicializado com sucesso.');
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error('Falha ao inicializar o Firebase', error, stackTrace);
      rethrow;
    }
  }
}
