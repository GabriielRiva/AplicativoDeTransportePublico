import 'package:flutter_test/flutter_test.dart';
import 'package:trancity/domain/entities/enums/driver_status.dart';
import 'package:trancity/domain/entities/line.dart';
import 'package:trancity/domain/entities/trip.dart';
import 'package:trancity/domain/usecases/passenger/get_nearby_buses.dart';

void main() {
  const GetNearbyBuses getNearbyBuses = GetNearbyBuses();

  const Line line101 = Line(
    id: 'line_101',
    number: 'L101',
    name: 'Centro/Ecoparque',
    description: 'Centro → Ecoparque',
    distance: 8.5,
    averageDuration: 35,
    color: '#4A9EBF',
  );
  const Line line102 = Line(
    id: 'line_102',
    number: 'L102',
    name: 'Efapi',
    description: 'Centro → Efapi',
    distance: 10.2,
    averageDuration: 40,
    color: '#2E9E4F',
  );

  Trip buildTrip(String id, String lineId, double latitude) {
    return Trip(
      id: id,
      driverId: id,
      busId: 'bus_$id',
      lineId: lineId,
      startedAt: DateTime(2026),
      status: DriverStatus.tripStarted,
      currentLatitude: latitude,
      currentLongitude: -52.6152,
    );
  }

  test('ordena os ônibus do mais próximo ao mais distante (RF13)', () {
    final List<NearbyBus> result = getNearbyBuses(
      userLatitude: -27.1004,
      userLongitude: -52.6152,
      trips: <Trip>[
        buildTrip('longe', 'line_102', -27.2000),
        buildTrip('perto', 'line_101', -27.1010),
      ],
      lines: const <Line>[line101, line102],
    );

    expect(result, hasLength(2));
    expect(result.first.trip.id, 'perto');
    expect(result.first.distanceKm, lessThan(result.last.distanceKm));
  });

  test('ignora trajetos de linhas não cadastradas', () {
    final List<NearbyBus> result = getNearbyBuses(
      userLatitude: -27.1004,
      userLongitude: -52.6152,
      trips: <Trip>[buildTrip('t1', 'linha_inexistente', -27.1010)],
      lines: const <Line>[line101],
    );

    expect(result, isEmpty);
  });

  test('respeita o limite máximo de resultados', () {
    final List<NearbyBus> result = getNearbyBuses(
      userLatitude: -27.1004,
      userLongitude: -52.6152,
      trips: <Trip>[
        buildTrip('t1', 'line_101', -27.1010),
        buildTrip('t2', 'line_101', -27.1020),
        buildTrip('t3', 'line_102', -27.1030),
        buildTrip('t4', 'line_102', -27.1040),
      ],
      lines: const <Line>[line101, line102],
      maxResults: 3,
    );

    expect(result, hasLength(3));
  });
}
