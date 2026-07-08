import 'package:logger/logger.dart';

/// Logger central do aplicativo (PROJECT_RULES: utilizar Logger).
abstract final class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, errorMethodCount: 5),
  );

  /// Registra informações de fluxo (login realizado, trajeto iniciado...).
  static void info(String message) => _logger.i(message);

  /// Registra avisos não críticos.
  static void warning(String message) => _logger.w(message);

  /// Registra erros com a exceção e o stack trace originais.
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
