import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trancity/core/constants/app_constants.dart';
import 'package:trancity/core/services/password_reset_cooldown.dart';

void main() {
  late DateTime now;
  DateTime clock() => now;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    now = DateTime(2026, 10, 24, 10);
  });

  test('libera o envio quando nenhum e-mail foi pedido', () async {
    final PasswordResetCooldown cooldown = PasswordResetCooldown(clock: clock);

    expect(await cooldown.remaining(), Duration.zero);
  });

  test('bloqueia o reenvio logo depois de um envio', () async {
    final PasswordResetCooldown cooldown = PasswordResetCooldown(clock: clock);
    await cooldown.markSent();

    now = now.add(const Duration(seconds: 20));

    expect(
      await cooldown.remaining(),
      kPasswordResetCooldown - const Duration(seconds: 20),
    );
  });

  test('libera o reenvio depois da espera', () async {
    final PasswordResetCooldown cooldown = PasswordResetCooldown(clock: clock);
    await cooldown.markSent();

    now = now.add(kPasswordResetCooldown);

    expect(await cooldown.remaining(), Duration.zero);
  });

  test('a espera continua mesmo reabrindo o app', () async {
    await PasswordResetCooldown(clock: clock).markSent();
    now = now.add(const Duration(seconds: 10));

    // Nova instância lê o último envio salvo no aparelho.
    final PasswordResetCooldown reopened = PasswordResetCooldown(clock: clock);

    expect(
      await reopened.remaining(),
      kPasswordResetCooldown - const Duration(seconds: 10),
    );
  });
}
