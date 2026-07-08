import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trancity/domain/repositories/driver_repository.dart';
import 'package:trancity/domain/usecases/driver/finish_trip.dart';

class MockDriverRepository extends Mock implements DriverRepository {}

void main() {
  test('encerra o trajeto do motorista informado (RF05)', () async {
    final MockDriverRepository repository = MockDriverRepository();
    final FinishTrip finishTrip = FinishTrip(repository);

    when(() => repository.finishTrip('uid1')).thenAnswer((_) async {});

    await finishTrip('uid1');

    verify(() => repository.finishTrip('uid1')).called(1);
  });
}
