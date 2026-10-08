import 'package:flutter_test/flutter_test.dart';
import 'package:trancity/domain/entities/speed_profile.dart';

void main() {
  const SpeedProfile profile = SpeedProfile.fallback;
  const int monday = DateTime.monday;
  const int saturday = DateTime.saturday;

  group('SpeedProfile.speedAt', () {
    test('usa a velocidade do pico em dia útil', () {
      expect(profile.speedAt(monday, 480), 13);
      expect(profile.speedAt(monday, 1080), 13);
    });

    test('pico não vale no sábado', () {
      expect(profile.speedAt(saturday, 480), 20);
    });

    test('fora das faixas usa a velocidade padrão', () {
      expect(profile.speedAt(monday, 600), 20);
      expect(profile.speedAt(monday, 1320), 25);
    });
  });

  group('SpeedProfile.secondsToTravel', () {
    test('1 km a 20 km/h leva 180 s, mais 20 s por ponto', () {
      expect(
        profile.secondsToTravel(1000, weekday: monday, startMinute: 600),
        closeTo(180, 0.01),
      );
      expect(
        profile.secondsToTravel(
          1000,
          weekday: monday,
          startMinute: 600,
          stops: 2,
        ),
        closeTo(220, 0.01),
      );
    });

    test('percurso que entra no pico usa as duas velocidades', () {
      // Sai 07:25: 5 min a 20 km/h (1666,7 m) e mais 5 min a 13 km/h
      // (1083,3 m) depois das 07:30.
      expect(
        profile.secondsToTravel(2750, weekday: monday, startMinute: 445),
        closeTo(600, 0.5),
      );
    });

    test('o mesmo percurso demora mais no pico', () {
      final double normal =
          profile.secondsToTravel(5000, weekday: monday, startMinute: 600);
      final double peak =
          profile.secondsToTravel(5000, weekday: monday, startMinute: 450);
      expect(peak, greaterThan(normal));
    });

    test('atravessa a meia-noite', () {
      final double seconds =
          profile.secondsToTravel(3000, weekday: monday, startMinute: 1439);
      // 3 km a 25 km/h (noite e madrugada) = 432 s.
      expect(seconds, closeTo(432, 0.5));
    });
  });
}
