import 'package:flutter_test/flutter_test.dart';
import 'package:trancity/data/models/speed_profile_model.dart';
import 'package:trancity/domain/entities/speed_profile.dart';

void main() {
  test('lê o nó speedProfile do Firebase', () {
    final SpeedProfileModel model = SpeedProfileModel.fromJson(
      <String, dynamic>{
        'defaultSpeedKmh': 18,
        'stopDwellSeconds': 30,
        'bands': <String, dynamic>{
          'pico': <String, dynamic>{
            'label': 'Pico',
            'start': '07:30',
            'end': '08:30',
            'speedKmh': 11,
            'weekdaysOnly': true,
          },
          'invalida': <String, dynamic>{
            'start': '09:00',
            'end': '08:00',
            'speedKmh': 30,
          },
        },
      },
    );
    expect(model.defaultSpeedKmh, 18);
    expect(model.stopDwellSeconds, 30);
    expect(model.bands, hasLength(1));
    expect(model.bands.single.startMinute, 450);
    expect(model.bands.single.endMinute, 510);
    expect(model.bands.single.weekdaysOnly, isTrue);
  });

  test('valores ausentes usam o perfil padrão', () {
    final SpeedProfileModel model =
        SpeedProfileModel.fromJson(<String, dynamic>{});
    expect(model.defaultSpeedKmh, SpeedProfile.fallback.defaultSpeedKmh);
    expect(model.bands, hasLength(SpeedProfile.fallback.bands.length));
  });
}
