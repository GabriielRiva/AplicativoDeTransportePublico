// precompute_routes.dart
//
// One-time BUILD-TIME script. Fetches street-following route polylines from the
// Google **Routes API** (computeRoutes) for each bus line and writes them to
// line_polylines.json. The app itself never calls the Routes API at runtime —
// it only reads the pre-computed encoded polyline stored on each line.
//
// The Directions API is legacy since 2025-03-01; new projects must use the
// Routes API. Enable "Routes API" in the Google Cloud console (same project as
// Maps), create a key for it (billing must be enabled), and pass that key here.
// This key is used only at build time and must NOT ship inside the app.
//
// Setup (any folder with `dart pub`, e.g. inside your Flutter project):
//   dart pub add http
//
// Input file (same folder), stops already ordered by `order` per line:
//   stops_input.json
//   { "line_101": [ {"lat": -27.098, "lng": -52.618}, ... ], "line_102": [...] }
//
// Run:
//   dart run precompute_routes.dart <ROUTES_API_KEY>
//
// Output (same folder):
//   line_polylines.json
//   { "line_101": "<encoded polyline>", "line_102": "...", "line_103": "..." }

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run precompute_routes.dart <ROUTES_API_KEY>');
    exitCode = 64;
    return;
  }
  final apiKey = args.first;

  final inputFile = File('stops_input.json');
  if (!inputFile.existsSync()) {
    stderr.writeln('Missing stops_input.json in the current directory.');
    exitCode = 66;
    return;
  }

  final lines = jsonDecode(inputFile.readAsStringSync()) as Map<String, dynamic>;
  final result = <String, String>{};
  final uri =
      Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes');

  for (final entry in lines.entries) {
    final lineId = entry.key;
    final stops = (entry.value as List)
        .map((s) => _LatLng(
              (s['lat'] as num).toDouble(),
              (s['lng'] as num).toDouble(),
            ))
        .toList();

    if (stops.length < 2) {
      stderr.writeln('[$lineId] needs at least 2 stops, skipping.');
      continue;
    }

    final origin = stops.first;
    final destination = stops.last;
    final intermediates = stops.sublist(1, stops.length - 1);

    final body = <String, dynamic>{
      'origin': _waypoint(origin),
      'destination': _waypoint(destination),
      if (intermediates.isNotEmpty)
        'intermediates': intermediates.map(_waypoint).toList(),
      'travelMode': 'DRIVE',
      'polylineEncoding': 'ENCODED_POLYLINE',
    };

    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'routes.polyline.encodedPolyline',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      stderr.writeln('[$lineId] HTTP ${response.statusCode}: ${response.body}');
      continue;
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = decoded['routes'] as List?;
    if (routes == null || routes.isEmpty) {
      stderr.writeln('[$lineId] no route returned: ${response.body}');
      continue;
    }

    final encoded = (routes.first['polyline']
        as Map<String, dynamic>)['encodedPolyline'] as String;
    result[lineId] = encoded;
    stdout.writeln('[$lineId] OK (${encoded.length} chars)');
  }

  File('line_polylines.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(result));
  stdout.writeln('Done. Wrote line_polylines.json with ${result.length} lines.');
}

Map<String, dynamic> _waypoint(_LatLng p) => <String, dynamic>{
      'location': <String, dynamic>{
        'latLng': <String, dynamic>{
          'latitude': p.lat,
          'longitude': p.lng,
        },
      },
    };

class _LatLng {
  const _LatLng(this.lat, this.lng);

  final double lat;
  final double lng;
}
