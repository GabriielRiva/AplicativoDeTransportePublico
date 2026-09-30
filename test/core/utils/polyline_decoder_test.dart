import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trancity/core/utils/polyline_decoder.dart';

void main() {
  group('PolylineDecoder.decode', () {
    test('string vazia retorna lista vazia', () {
      expect(PolylineDecoder.decode(''), isEmpty);
    });

    test('decodifica o exemplo canônico do algoritmo do Google', () {
      // Exemplo oficial da documentação do Encoded Polyline Algorithm
      // Format: https://developers.google.com/maps/documentation/utilities/polylinealgorithm
      final List<LatLng> points =
          PolylineDecoder.decode(r'_p~iF~ps|U_ulLnnqC_mqNvxq`@');

      expect(points, hasLength(3));
      expect(points[0].latitude, closeTo(38.5, 1e-5));
      expect(points[0].longitude, closeTo(-120.2, 1e-5));
      expect(points[1].latitude, closeTo(40.7, 1e-5));
      expect(points[1].longitude, closeTo(-120.95, 1e-5));
      expect(points[2].latitude, closeTo(43.252, 1e-5));
      expect(points[2].longitude, closeTo(-126.453, 1e-5));
    });

    test('decodifica o traçado real da line_101 (Terminal Centro)', () {
      // Polyline pré-calculada via Routes API e persistida em
      // routePolyline (linha_polylines.json), ponto inicial no
      // Terminal Urbano Centro (stops_input.json).
      const String line101Polyline =
          r'vqkdDx~c`I{Dl@_AgGU}ArCe@tA_@NBJK^KvDk@^In@vFdASeARXvB}FhAIBAJHFJE?KEEc@}Dm@oDHI^KvDk@jGkAzFgAV|ARnAf@dEkFv@oAiJzOwCnGmA^KJ@FKAMGC[yC`AMrAUxBcFOO?SbDo@jASpBa@fEs@_@iCa@wC?GtGkAjBa@';

      final List<LatLng> points = PolylineDecoder.decode(line101Polyline);

      expect(points, hasLength(56));
      expect(points.first.latitude, closeTo(-27.098, 1e-3));
      expect(points.first.longitude, closeTo(-52.618, 1e-3));
    });
  });
}
