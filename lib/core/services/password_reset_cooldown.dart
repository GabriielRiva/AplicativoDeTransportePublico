import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

/// Intervalo mínimo entre dois e-mails de recuperação de senha (RF17).
///
/// Sem esse limite, o usuário podia pedir reenvios sem fim: chegavam vários
/// e-mails com links diferentes, alguns já expirados, o que confunde, e os
/// pedidos repetidos sobrecarregavam o app. O horário do último envio fica
/// salvo no aparelho, então fechar a tela ou o app não zera a espera.
class PasswordResetCooldown {
  /// Cria o controle. [clock] permite fixar o horário nos testes.
  PasswordResetCooldown({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  static const String _key = 'password_reset_last_sent_at';

  final DateTime Function() _clock;
  DateTime? _lastSentAt;
  bool _loaded = false;

  /// Tempo que falta para poder pedir outro e-mail ([Duration.zero] se já
  /// pode).
  Future<Duration> remaining() async {
    final DateTime? last = await _load();
    if (last == null) return Duration.zero;
    final Duration elapsed = _clock().difference(last);
    // Relógio do aparelho voltou no tempo: não prende o usuário.
    if (elapsed.isNegative) return Duration.zero;
    final Duration left = kPasswordResetCooldown - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  /// Registra que um e-mail acabou de ser enviado.
  Future<void> markSent() async {
    final DateTime now = _clock();
    _lastSentAt = now;
    _loaded = true;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, now.millisecondsSinceEpoch);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Falha ao salvar envio de recuperação',
        error,
        stackTrace,
      );
    }
  }

  Future<DateTime?> _load() async {
    if (_loaded) return _lastSentAt;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int? millis = prefs.getInt(_key);
      _lastSentAt =
          millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Falha ao ler envio de recuperação',
        error,
        stackTrace,
      );
    }
    _loaded = true;
    return _lastSentAt;
  }
}
