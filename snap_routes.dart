// snap_routes.dart
//
// Script de BUILD (roda uma vez, fora do app). Gruda nas ruas os traçados
// desenhados no Google My Maps usando a Google **Roads API** (snapToRoads com
// interpolate=true). O KML exportado pelo My Maps traz uma versão
// simplificada do trajeto, que corta alguns metros nas curvas; o snap devolve
// o mesmo caminho, com todos os pontos sobre a rua.
//
// Setup: ativar "Roads API" no Google Cloud (mesmo projeto da Routes API,
// faturamento ativo) e usar uma chave com essa API liberada. A chave é usada
// só aqui e NÃO vai dentro do app.
//
// Entrada:  routes/drawn_routes.json
//   { "line_101": [[lat, lng], ...], "line_104": [...] }
// Execução (na raiz do projeto):
//   dart run snap_routes.dart <ROADS_API_KEY>
// Saída:    routes/snapped_routes.json  (mesmo formato da entrada)

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

/// Limite de pontos por requisição da Roads API.
const int _maxPointsPerRequest = 100;

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Uso: dart run snap_routes.dart <ROADS_API_KEY>');
    exitCode = 64;
    return;
  }
  final String apiKey = args.first;

  final File input = File('routes/drawn_routes.json');
  if (!input.existsSync()) {
    stderr.writeln('Arquivo routes/drawn_routes.json não encontrado.');
    exitCode = 66;
    return;
  }

  final Map<String, dynamic> lines =
      jsonDecode(input.readAsStringSync()) as Map<String, dynamic>;
  final Map<String, List<List<double>>> result =
      <String, List<List<double>>>{};

  for (final MapEntry<String, dynamic> entry in lines.entries) {
    final List<List<double>> points = (entry.value as List<dynamic>)
        .map((dynamic p) => <double>[
              ((p as List<dynamic>)[0] as num).toDouble(),
              (p[1] as num).toDouble(),
            ])
        .toList();
    if (points.length < 2) {
      stderr.writeln('[${entry.key}] precisa de pelo menos 2 pontos.');
      continue;
    }

    final List<List<double>> snapped = <List<double>>[];
    bool failed = false;
    // Blocos de até 100 pontos, com 1 ponto em comum entre blocos vizinhos
    // para o trajeto continuar sem buracos.
    for (int start = 0;; start += _maxPointsPerRequest - 1) {
      final int end = math.min(start + _maxPointsPerRequest, points.length);
      final String path = points
          .sublist(start, end)
          .map((List<double> p) => '${p[0]},${p[1]}')
          .join('|');
      final Uri uri = Uri.https('roads.googleapis.com', '/v1/snapToRoads',
          <String, String>{
        'path': path,
        'interpolate': 'true',
        'key': apiKey,
      });

      final http.Response response = await http.get(uri);
      if (response.statusCode != 200) {
        stderr.writeln(
          '[${entry.key}] HTTP ${response.statusCode}: ${response.body}',
        );
        failed = true;
        break;
      }

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> snappedPoints =
          (body['snappedPoints'] as List<dynamic>?) ?? const <dynamic>[];
      for (final dynamic sp in snappedPoints) {
        final Map<String, dynamic> location =
            (sp as Map<String, dynamic>)['location'] as Map<String, dynamic>;
        final List<double> point = <double>[
          (location['latitude'] as num).toDouble(),
          (location['longitude'] as num).toDouble(),
        ];
        final bool duplicate = snapped.isNotEmpty &&
            snapped.last[0] == point[0] &&
            snapped.last[1] == point[1];
        if (!duplicate) snapped.add(point);
      }

      if (end == points.length) break;
    }

    if (failed || snapped.length < 2) {
      stderr.writeln('[${entry.key}] não foi possível ajustar às ruas.');
      continue;
    }
    result[entry.key] = snapped;
    stdout.writeln(
      '[${entry.key}] OK: ${points.length} pontos desenhados -> '
      '${snapped.length} pontos na rua',
    );
  }

  File('routes/snapped_routes.json')
      .writeAsStringSync(jsonEncode(result));
  stdout.writeln(
    'Pronto. routes/snapped_routes.json com ${result.length} linhas.',
  );
}
