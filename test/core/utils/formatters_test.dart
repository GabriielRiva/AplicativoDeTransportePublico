import 'package:flutter_test/flutter_test.dart';
import 'package:trancity/core/utils/formatters.dart';

void main() {
  group('Formatters.distanceMeters', () {
    test('até 1 km mostra metros arredondados de 10 em 10', () {
      expect(Formatters.distanceMeters(0), '0 m');
      expect(Formatters.distanceMeters(43), '40 m');
      expect(Formatters.distanceMeters(318), '320 m');
    });

    test('a partir de 1 km mostra km com uma casa decimal', () {
      expect(Formatters.distanceMeters(1000), '1,0 km');
      expect(Formatters.distanceMeters(1240), '1,2 km');
    });
  });
}
