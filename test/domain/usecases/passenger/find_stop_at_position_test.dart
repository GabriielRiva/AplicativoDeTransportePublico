import 'package:flutter_test/flutter_test.dart';
import 'package:trancity/domain/entities/stop.dart';
import 'package:trancity/domain/usecases/passenger/find_stop_at_position.dart';

void main() {
  const FindStopAtPosition findStop = FindStopAtPosition();

  // ~0,0001° de latitude ≈ 11 m.
  const List<Stop> stops = <Stop>[
    Stop(
      id: 's1',
      lineId: 'line_105',
      name: 'Parada 1',
      latitude: -27.1139,
      longitude: -52.5979,
      order: 1,
    ),
    Stop(
      id: 's2',
      lineId: 'line_105',
      name: 'Parada 2',
      latitude: -27.1135,
      longitude: -52.6020,
      order: 2,
    ),
  ];

  test('retorna a parada quando o ônibus está dentro do raio', () {
    final Stop? stop = findStop(
      stops: stops,
      latitude: -27.1137,
      longitude: -52.6020,
    );
    expect(stop?.id, 's2');
  });

  test('retorna null quando o ônibus está longe de todas as paradas', () {
    final Stop? stop = findStop(
      stops: stops,
      latitude: -27.1150,
      longitude: -52.6000,
    );
    expect(stop, isNull);
  });

  test('escolhe a parada mais próxima quando há mais de uma no raio', () {
    final Stop? stop = findStop(
      stops: stops,
      latitude: -27.1139,
      longitude: -52.5980,
      radiusMeters: 1000,
    );
    expect(stop?.id, 's1');
  });

  test('lista vazia retorna null', () {
    expect(
      findStop(stops: const <Stop>[], latitude: 0, longitude: 0),
      isNull,
    );
  });
}
