import 'package:flutter_test/flutter_test.dart';
import 'package:trancity/domain/entities/speed_profile.dart';
import 'package:trancity/domain/usecases/passenger/bus_speed_tracker.dart';
import 'package:trancity/domain/usecases/passenger/estimate_arrival.dart';

void main() {
  // Segunda-feira, 10:00 (fora do pico: 20 km/h).
  final DateTime monday10h = DateTime(2026, 10, 5, 10);
  const EstimateArrival estimate = EstimateArrival(SpeedProfile.fallback);

  group('EstimateArrival', () {
    test('sem velocidade real usa a faixa de horário', () {
      expect(
        estimate.seconds(meters: 2000, now: monday10h),
        closeTo(360, 0.5),
      );
      expect(estimate.minutes(meters: 2000, now: monday10h), 6);
    });

    test('soma o tempo parado nos pontos do caminho', () {
      expect(
        estimate.seconds(meters: 2000, now: monday10h, stopsOnTheWay: 3),
        closeTo(420, 0.5),
      );
    });

    test('ônibus mais lento que a média aumenta a estimativa', () {
      final double planned = estimate.seconds(meters: 2000, now: monday10h);
      final double slow = estimate.seconds(
        meters: 2000,
        now: monday10h,
        observed: (speedKmh: 10, window: const Duration(minutes: 5)),
      );
      // Peso máximo 70%: 0,7 × 720 s + 0,3 × 360 s = 612 s.
      expect(slow, closeTo(612, 0.5));
      expect(slow, greaterThan(planned));
    });

    test('pouco tempo observado pesa pouco', () {
      expect(
        EstimateArrival.observedWeight(const Duration(minutes: 1)),
        closeTo(0.14, 0.001),
      );
    });
  });

  group('BusSpeedTracker', () {
    final DateTime start = DateTime(2026, 10, 5, 10);

    test('mede a velocidade pelo quanto andou na rota', () {
      final BusSpeedTracker tracker = BusSpeedTracker()
        ..add(start, 0)
        ..add(start.add(const Duration(minutes: 1)), 300)
        ..add(start.add(const Duration(minutes: 2)), 600);
      final ObservedSpeed? speed = tracker.speed;
      expect(speed, isNotNull);
      // 600 m em 2 min = 18 km/h.
      expect(speed!.speedKmh, closeTo(18, 0.01));
      expect(speed.window, const Duration(minutes: 2));
    });

    test('menos de 1 minuto observado não vale', () {
      final BusSpeedTracker tracker = BusSpeedTracker()
        ..add(start, 0)
        ..add(start.add(const Duration(seconds: 30)), 200);
      expect(tracker.speed, isNull);
    });

    test('ônibus parado no terminal não vale', () {
      final BusSpeedTracker tracker = BusSpeedTracker()
        ..add(start, 0)
        ..add(start.add(const Duration(minutes: 3)), 10);
      expect(tracker.speed, isNull);
    });

    test('nova volta da linha recomeça a medida', () {
      final BusSpeedTracker tracker = BusSpeedTracker()
        ..add(start, 5000)
        ..add(start.add(const Duration(minutes: 2)), 5600)
        ..add(start.add(const Duration(minutes: 3)), 20);
      expect(tracker.speed, isNull);
    });

    test('descarta posições com mais de 5 minutos', () {
      final BusSpeedTracker tracker = BusSpeedTracker()
        ..add(start, 0)
        ..add(start.add(const Duration(minutes: 4)), 400)
        ..add(start.add(const Duration(minutes: 7)), 1300);
      // Fica de 4 a 7 min: 900 m em 3 min = 18 km/h.
      expect(tracker.speed!.speedKmh, closeTo(18, 0.01));
    });
  });
}
