import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trancity/domain/entities/line.dart';
import 'package:trancity/domain/repositories/line_repository.dart';
import 'package:trancity/domain/usecases/passenger/get_line_route.dart';

class MockLineRepository extends Mock implements LineRepository {}

void main() {
  late MockLineRepository lineRepository;
  late GetLineRoute getLineRoute;

  const Line lineWithRoute = Line(
    id: 'line_101',
    number: 'L101',
    name: 'Centro/Ecoparque',
    description: 'Centro → Ecoparque',
    distance: 8.5,
    averageDuration: 35,
    color: '#4A9EBF',
    routePolyline: r'_p~iF~ps|U_ulLnnqC_mqNvxq`@',
  );

  const Line lineWithoutRoute = Line(
    id: 'line_103',
    number: 'L103',
    name: 'H. Regional',
    description: 'Centro → Hospital Regional',
    distance: 5.4,
    averageDuration: 20,
    color: '#E5484D',
  );

  setUp(() {
    lineRepository = MockLineRepository();
    getLineRoute = GetLineRoute(lineRepository);
  });

  test('decodifica a routePolyline da linha (RF09)', () async {
    when(() => lineRepository.getLineById('line_101'))
        .thenAnswer((_) async => lineWithRoute);

    final List<LatLng> points = await getLineRoute('line_101');

    expect(points, hasLength(3));
    expect(points.first.latitude, closeTo(38.5, 1e-5));
    verify(() => lineRepository.getLineById('line_101')).called(1);
  });

  test('retorna lista vazia quando a linha ainda não possui rota semeada',
      () async {
    when(() => lineRepository.getLineById('line_103'))
        .thenAnswer((_) async => lineWithoutRoute);

    final List<LatLng> points = await getLineRoute('line_103');

    expect(points, isEmpty);
  });
}
