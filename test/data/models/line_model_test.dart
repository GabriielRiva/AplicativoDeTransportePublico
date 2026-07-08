import 'package:flutter_test/flutter_test.dart';
import 'package:trancity/data/models/line_model.dart';

void main() {
  group('LineModel.fromJson', () {
    test('lê a chave averageDuration (API_SPEC)', () {
      final LineModel line = LineModel.fromJson('line_101', <String, dynamic>{
        'number': 'L101',
        'name': 'Centro/Ecoparque',
        'description': 'Centro → Ecoparque',
        'distance': 8.5,
        'averageDuration': 35,
        'color': '#4A9EBF',
      });

      expect(line.averageDuration, 35);
      expect(line.displayName, 'L101 - Centro/Ecoparque');
    });

    test('aceita a chave averageTime (FIREBASE_SCHEMA) como fallback', () {
      final LineModel line = LineModel.fromJson('line_102', <String, dynamic>{
        'name': 'Efapi',
        'description': 'Centro → Efapi',
        'distance': 10.2,
        'averageTime': 40,
      });

      expect(line.averageDuration, 40);
    });

    test('usa valores padrão seguros para campos ausentes', () {
      final LineModel line =
          LineModel.fromJson('line_103', <String, dynamic>{});
      expect(line.distance, 0);
      expect(line.color, '#4A9EBF');
      expect(line.number, 'line_103');
    });
  });

  group('LineModel.toJson', () {
    test('serializa todos os campos da linha', () {
      const LineModel line = LineModel(
        id: 'line_101',
        number: 'L101',
        name: 'Centro/Ecoparque',
        description: 'Centro → Ecoparque',
        distance: 8.5,
        averageDuration: 35,
        color: '#4A9EBF',
      );

      final Map<String, dynamic> json = line.toJson();
      expect(json['number'], 'L101');
      expect(json['distance'], 8.5);
      expect(json['averageDuration'], 35);
    });
  });
}
