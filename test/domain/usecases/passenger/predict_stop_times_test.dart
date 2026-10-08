import 'package:flutter_test/flutter_test.dart';
import 'package:trancity/domain/entities/schedule.dart';
import 'package:trancity/domain/entities/speed_profile.dart';
import 'package:trancity/domain/entities/stop.dart';
import 'package:trancity/domain/usecases/passenger/predict_stop_times.dart';

Stop _stop(int order) => Stop(
      id: 's$order',
      lineId: 'l1',
      name: 'Ponto $order',
      latitude: 0,
      longitude: 0,
      order: order,
    );

void main() {
  const PredictStopTimes predict = PredictStopTimes();
  final List<Stop> stops = <Stop>[_stop(1), _stop(2), _stop(3)];
  const List<double> meters = <double>[0, 1000, 2000];

  test('soma o tempo de percurso e o tempo parado nos pontos', () {
    const Schedule schedule = Schedule(
      id: 'h1',
      lineId: 'l1',
      departureTime: '10:00',
      weekday: DateTime.monday,
    );
    final List<StopTime> times = predict(
      schedule: schedule,
      stops: stops,
      stopMeters: meters,
      profile: SpeedProfile.fallback,
    );
    // 20 km/h: 1 km = 3 min; o ponto 3 soma 20 s parado no ponto 2.
    expect(
      times.map((StopTime t) => t.minuteOfDay),
      <int>[600, 603, 606],
    );
  });

  test('no pico os horários ficam mais espaçados', () {
    const Schedule schedule = Schedule(
      id: 'h2',
      lineId: 'l1',
      departureTime: '07:30',
      weekday: DateTime.monday,
    );
    final List<StopTime> times = predict(
      schedule: schedule,
      stops: stops,
      stopMeters: meters,
      profile: SpeedProfile.fallback,
    );
    // 13 km/h: 1 km ≈ 4,6 min.
    expect(times[1].minuteOfDay, 450 + 5);
  });

  test('horário de saída inválido não gera previsão', () {
    const Schedule schedule = Schedule(
      id: 'h3',
      lineId: 'l1',
      departureTime: 'xx',
      weekday: DateTime.monday,
    );
    expect(
      predict(
        schedule: schedule,
        stops: stops,
        stopMeters: meters,
        profile: SpeedProfile.fallback,
      ),
      isEmpty,
    );
  });
}
