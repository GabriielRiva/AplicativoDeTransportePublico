import 'package:flutter_test/flutter_test.dart';
import 'package:trancity/domain/entities/speed_profile.dart';
import 'package:trancity/domain/usecases/passenger/estimate_between_stops.dart';

void main() {
  const EstimateBetweenStops estimate = EstimateBetweenStops();
  // Segunda-feira, 10:00 (fora do pico: 20 km/h, 20 s por ponto).
  final DateTime monday10h = DateTime(2026, 10, 5, 10);
  const List<double> meters = <double>[0, 1000, 2000, 3000];

  StopToStop? between(int from, int to, {bool circular = false}) =>
      estimate(
        stopMeters: meters,
        from: from,
        to: to,
        isCircular: circular,
        totalMeters: 4000,
        profile: SpeedProfile.fallback,
        departure: monday10h,
      );

  test('soma distância pela rua e tempo parado nos pontos do meio', () {
    final StopToStop? result = between(0, 3);
    expect(result, isNotNull);
    expect(result!.meters, 3000);
    expect(result.stopsOnTheWay, 2);
    // 3 km a 20 km/h = 9 min, mais 2 × 20 s ≈ 9,7 min.
    expect(result.minutes, 10);
  });

  test('pontos vizinhos não têm paradas no caminho', () {
    final StopToStop? result = between(1, 2);
    expect(result!.stopsOnTheWay, 0);
    expect(result.minutes, 3);
  });

  test('destino antes da origem não vale em linha só de ida', () {
    expect(between(2, 1), isNull);
  });

  test('em linha circular dá a volta até o destino', () {
    final StopToStop? result = between(3, 1, circular: true);
    // Do km 3 até o fim (km 4) e do início até o km 1.
    expect(result!.meters, 2000);
    expect(result.stopsOnTheWay, 1);
  });

  test('mesma parada não tem estimativa', () {
    expect(between(1, 1), isNull);
  });
}
