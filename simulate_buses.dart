// simulate_buses.dart
//
// Simulador de ônibus para testes e para a gravação do vídeo (roda fora do
// app, no computador). Cada ônibus do arquivo de configuração entra com uma
// conta de MOTORISTA e percorre o traçado da linha em loop, gravando a
// posição em drivers/{uid} a cada 1 segundo, exatamente como o app do
// motorista faz. Para os passageiros, é um ônibus de verdade em trajeto.
//
// Preparação:
//   1. Crie no app uma conta de motorista para cada ônibus simulado (não
//      use a mesma conta de quem vai dirigir de verdade).
//   2. Copie simulador.exemplo.json para simulador.json e preencha os
//      e-mails e senhas. O simulador.json fica fora do Git (.gitignore).
//   3. O arquivo android/app/google-services.json precisa existir (é de
//      onde saem a chave e o endereço do Firebase).
//
// Execução (na raiz do projeto):
//   dart run simulate_buses.dart
// Ctrl+C encerra os trajetos (status trip_finished) e fecha o simulador.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

/// Intervalo entre duas posições enviadas (o mesmo do app do motorista).
const Duration _tick = Duration(seconds: 1);

/// Espera no fim da linha antes de recomeçar o trajeto do início.
const Duration _endOfLineWait = Duration(seconds: 30);

Future<void> main(List<String> args) async {
  final _FirebaseConfig firebase;
  final _SimulatorConfig config;
  try {
    config = _SimulatorConfig.load('simulador.json');
    firebase = await _FirebaseConfig.load(
      'android/app/google-services.json',
      databaseUrl: config.databaseUrl,
    );
    stdout.writeln('Banco: ${firebase.databaseUrl}');
  } on _SetupException catch (error) {
    stderr.writeln(error.message);
    exitCode = 66;
    return;
  }

  final List<_SimulatedBus> buses = <_SimulatedBus>[];
  for (final _BusConfig bus in config.buses) {
    try {
      final _SimulatedBus simulated =
          await _SimulatedBus.start(firebase, config, bus);
      buses.add(simulated);
      stdout.writeln(
        '[${simulated.label}] trajeto iniciado '
        '(${(simulated.routeLength / 1000).toStringAsFixed(1)} km, '
        '${simulated.stopCount} paradas).',
      );
    } on _SetupException catch (error) {
      stderr.writeln('[${bus.lineId}] ${error.message}');
    }
  }
  if (buses.isEmpty) {
    stderr.writeln('Nenhum ônibus iniciado. Confira o simulador.json.');
    exitCode = 1;
    return;
  }
  stdout.writeln(
    '\n${buses.length} ônibus em circulação. Ctrl+C para encerrar.\n',
  );

  int ticks = 0;
  final Timer timer = Timer.periodic(_tick, (_) {
    ticks++;
    for (final _SimulatedBus bus in buses) {
      bus.step(_tick);
    }
    // Resumo a cada 15 s, sem poluir o terminal.
    if (ticks % 15 == 0) {
      for (final _SimulatedBus bus in buses) {
        stdout.writeln(bus.status());
      }
      stdout.writeln('');
    }
  });

  late final StreamSubscription<ProcessSignal> signals;
  signals = ProcessSignal.sigint.watch().listen((_) async {
    timer.cancel();
    stdout.writeln('\nEncerrando os trajetos...');
    await Future.wait(buses.map((_SimulatedBus bus) => bus.finish()));
    stdout.writeln('Pronto.');
    await signals.cancel();
    exit(0);
  });
}

/// Erro de preparação com mensagem pronta para o terminal.
class _SetupException implements Exception {
  const _SetupException(this.message);

  final String message;
}

/// Chave da API e endereço do Realtime Database do google-services.json.
class _FirebaseConfig {
  const _FirebaseConfig(this.apiKey, this.databaseUrl);

  /// Lê a chave da API do [path]. O endereço do banco vem de
  /// [databaseUrl] (campo "bancoUrl" do simulador.json), do firebase_url do
  /// google-services.json ou, se nenhum existir, do endereço padrão do
  /// projeto; se o banco estiver em outra região, o próprio Firebase
  /// informa o endereço certo, que passa a ser usado.
  static Future<_FirebaseConfig> load(
    String path, {
    String? databaseUrl,
  }) async {
    final File file = File(path);
    if (!file.existsSync()) {
      throw _SetupException('Arquivo $path não encontrado.');
    }
    final Map<String, dynamic> json =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final Map<String, dynamic> project =
        json['project_info'] as Map<String, dynamic>;
    final List<dynamic> clients = json['client'] as List<dynamic>;
    final Map<String, dynamic> client = clients.first as Map<String, dynamic>;
    final List<dynamic> keys = client['api_key'] as List<dynamic>;
    final String apiKey =
        (keys.first as Map<String, dynamic>)['current_key'] as String;
    final String projectId = project['project_id'] as String;
    final String url = databaseUrl ??
        project['firebase_url'] as String? ??
        'https://$projectId-default-rtdb.firebaseio.com';
    return _FirebaseConfig(apiKey, await _resolveRegion(url));
  }

  /// Bancos fora dos EUA têm outro endereço; o Firebase avisa qual é.
  static Future<String> _resolveRegion(String url) async {
    final String base =
        url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    try {
      final http.Response response =
          await http.get(Uri.parse('$base/.json?shallow=true'));
      final RegExpMatch? match = RegExp(
        r'different region.*?(https://[^\s"]+)',
      ).firstMatch(response.body);
      if (match != null) {
        // Tira a barra ou o ponto final que vêm grudados no endereço.
        return match.group(1)!.replaceAll(RegExp(r'[./]+$'), '');
      }
      if (response.statusCode == 404) {
        throw _SetupException(
          'Banco não encontrado em $base. Copie o endereço que aparece no '
          'topo de Realtime Database > Dados, no Firebase Console, para o '
          'campo "bancoUrl" do simulador.json.',
        );
      }
    } on http.ClientException catch (error) {
      throw _SetupException('Sem conexão com $base: ${error.message}');
    } on SocketException catch (error) {
      throw _SetupException('Sem conexão com $base: ${error.message}');
    }
    return base;
  }

  final String apiKey;
  final String databaseUrl;
}

/// Conteúdo do simulador.json.
class _SimulatorConfig {
  const _SimulatorConfig({
    required this.databaseUrl,
    required this.speedKmh,
    required this.stopSeconds,
    required this.buses,
  });

  factory _SimulatorConfig.load(String path) {
    final File file = File(path);
    if (!file.existsSync()) {
      throw _SetupException(
        'Arquivo $path não encontrado. Copie simulador.exemplo.json para '
        '$path e preencha as contas de motorista.',
      );
    }
    final Map<String, dynamic> json =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final List<dynamic> buses = json['onibus'] as List<dynamic>;
    return _SimulatorConfig(
      databaseUrl: json['bancoUrl'] as String?,
      speedKmh: (json['velocidadeKmh'] as num? ?? 20).toDouble(),
      stopSeconds: (json['paradaSegundos'] as num? ?? 15).toInt(),
      buses: buses
          .map(
            (dynamic bus) => _BusConfig.fromJson(bus as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  /// Endereço do Realtime Database (opcional; ver [_FirebaseConfig.load]).
  final String? databaseUrl;

  /// Velocidade do ônibus em movimento.
  final double speedKmh;

  /// Tempo parado em cada ponto de parada.
  final int stopSeconds;

  final List<_BusConfig> buses;
}

/// Um ônibus simulado do simulador.json.
class _BusConfig {
  const _BusConfig({
    required this.lineId,
    required this.busId,
    required this.email,
    required this.password,
    required this.startFraction,
  });

  factory _BusConfig.fromJson(Map<String, dynamic> json) {
    return _BusConfig(
      lineId: json['linha'] as String,
      busId: json['onibus'] as String,
      email: json['email'] as String,
      password: json['senha'] as String,
      startFraction:
          ((json['inicio'] as num? ?? 0).toDouble()).clamp(0.0, 0.99),
    );
  }

  final String lineId;
  final String busId;
  final String email;
  final String password;

  /// Onde o ônibus começa, em fração do traçado (0 = início da linha).
  final double startFraction;
}

/// Sessão de um motorista no Firebase (REST), com renovação do token.
class _Session {
  _Session(
    this._apiKey,
    this.uid,
    this._idToken,
    this._refreshToken,
    this._expiresAt,
  );

  static Future<_Session> signIn(
    String apiKey,
    String email,
    String password,
  ) async {
    final http.Response response = await http.post(
      Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/'
        'accounts:signInWithPassword?key=$apiKey',
      ),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, Object>{
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );
    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      final Map<String, dynamic>? error =
          json['error'] as Map<String, dynamic>?;
      throw _SetupException(
        'Não foi possível entrar com $email: '
        '${error?['message'] ?? response.statusCode}.',
      );
    }
    return _Session(
      apiKey,
      json['localId'] as String,
      json['idToken'] as String,
      json['refreshToken'] as String,
      DateTime.now().add(
        Duration(seconds: int.parse(json['expiresIn'] as String)),
      ),
    );
  }

  final String _apiKey;
  final String uid;
  String _idToken;
  String _refreshToken;
  DateTime _expiresAt;

  /// Token válido, renovado 5 minutos antes de expirar (expira em 1 hora).
  Future<String> token() async {
    if (DateTime.now()
        .isBefore(_expiresAt.subtract(const Duration(minutes: 5)))) {
      return _idToken;
    }
    final http.Response response = await http.post(
      Uri.parse('https://securetoken.googleapis.com/v1/token?key=$_apiKey'),
      body: <String, String>{
        'grant_type': 'refresh_token',
        'refresh_token': _refreshToken,
      },
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;
      _idToken = json['id_token'] as String;
      _refreshToken = json['refresh_token'] as String;
      _expiresAt = DateTime.now().add(
        Duration(seconds: int.parse(json['expires_in'] as String)),
      );
    }
    return _idToken;
  }
}

/// Acesso REST ao Realtime Database com a sessão do motorista.
class _Database {
  const _Database(this._baseUrl, this._session);

  final String _baseUrl;
  final _Session _session;

  Future<Uri> _uri(String path, [Map<String, String>? query]) async {
    return Uri.parse('$_baseUrl/$path.json').replace(
      queryParameters: <String, String>{
        'auth': await _session.token(),
        ...?query,
      },
    );
  }

  Future<Object?> get(String path, [Map<String, String>? query]) async {
    final http.Response response = await http.get(await _uri(path, query));
    if (response.statusCode != 200) {
      throw _SetupException(
        'Falha ao ler $path (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body);
  }

  Future<void> put(String path, Map<String, Object?> data) async {
    final http.Response response =
        await http.put(await _uri(path), body: jsonEncode(data));
    if (response.statusCode != 200) {
      throw _SetupException(
        'Falha ao gravar $path (${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<void> patch(String path, Map<String, Object?> data) async {
    final http.Response response =
        await http.patch(await _uri(path), body: jsonEncode(data));
    if (response.statusCode != 200) {
      throw _SetupException(
        'Falha ao gravar $path (${response.statusCode}): ${response.body}',
      );
    }
  }
}

/// Horário do servidor do Firebase (as regras exigem updatedAt == now).
const Map<String, String> _serverTime = <String, String>{'.sv': 'timestamp'};

/// Ônibus percorrendo o traçado da linha em loop.
class _SimulatedBus {
  _SimulatedBus._({
    required this.label,
    required this.config,
    required _Database database,
    required _Session session,
    required List<_Point> route,
    required List<double> cumulative,
    required List<({String name, double meters})> stops,
    required double startMeters,
  })  : _database = database,
        _session = session,
        _route = route,
        _cumulative = cumulative,
        _stops = stops,
        _meters = startMeters;

  static Future<_SimulatedBus> start(
    _FirebaseConfig firebase,
    _SimulatorConfig config,
    _BusConfig bus,
  ) async {
    final _Session session =
        await _Session.signIn(firebase.apiKey, bus.email, bus.password);
    final _Database database = _Database(firebase.databaseUrl, session);

    final Object? role = await database.get('users/${session.uid}/role');
    if (role != 'driver') {
      throw _SetupException(
        '${bus.email} não é uma conta de motorista (role: $role).',
      );
    }

    final Object? line = await database.get('lines/${bus.lineId}');
    if (line is! Map<String, dynamic>) {
      throw _SetupException('Linha ${bus.lineId} não encontrada.');
    }
    final List<_Point> route =
        _decodePolyline(line['routePolyline'] as String? ?? '');
    if (route.length < 2) {
      throw _SetupException('A linha ${bus.lineId} não tem traçado.');
    }
    final List<double> cumulative = <double>[0];
    for (int i = 1; i < route.length; i++) {
      cumulative.add(cumulative.last + _distanceMeters(route[i - 1], route[i]));
    }

    final Object? rawStops = await database.get('stops', <String, String>{
      'orderBy': '"lineId"',
      'equalTo': '"${bus.lineId}"',
    });
    final List<({String name, double meters})> stops =
        <({String name, double meters})>[];
    if (rawStops is Map<String, dynamic>) {
      for (final Object? value in rawStops.values) {
        if (value is! Map<String, dynamic>) continue;
        final _Point stop = _Point(
          (value['latitude'] as num).toDouble(),
          (value['longitude'] as num).toDouble(),
        );
        stops.add((
          name: value['name'] as String? ?? 'Parada',
          meters: _project(route, cumulative, stop),
        ));
      }
      stops.sort(
        (({String name, double meters}) a, ({String name, double meters}) b) =>
            a.meters.compareTo(b.meters),
      );
    }

    final String number = line['number'] as String? ?? bus.lineId;
    final _SimulatedBus simulated = _SimulatedBus._(
      label: '$number ${bus.busId}',
      config: config,
      database: database,
      session: session,
      route: route,
      cumulative: cumulative,
      stops: stops,
      startMeters: cumulative.last * bus.startFraction,
    );
    final _Point position = simulated._pointAt(simulated._meters);
    await database.put('drivers/${session.uid}', <String, Object?>{
      'busId': bus.busId,
      'lineId': bus.lineId,
      'startedAt': _serverTime,
      'status': 'trip_started',
      'latitude': position.lat,
      'longitude': position.lng,
      'updatedAt': _serverTime,
    });
    simulated._nextStop = simulated._stopIndexAfter(simulated._meters);
    return simulated;
  }

  final String label;
  final _SimulatorConfig config;
  final _Database _database;
  final _Session _session;
  final List<_Point> _route;
  final List<double> _cumulative;
  final List<({String name, double meters})> _stops;

  double _meters;
  int _nextStop = 0;
  Duration _waiting = Duration.zero;
  bool _sending = false;
  int _failures = 0;

  double get routeLength => _cumulative.last;
  int get stopCount => _stops.length;

  /// Avança o ônibus [elapsed] e envia a nova posição.
  void step(Duration elapsed) {
    if (_waiting > Duration.zero) {
      _waiting -= elapsed;
    } else if (_meters >= routeLength) {
      // Fim da linha: recomeça do início.
      _meters = 0;
      _nextStop = _stopIndexAfter(0);
    } else {
      final double speed = config.speedKmh / 3.6;
      double next = _meters + speed * elapsed.inMilliseconds / 1000;
      if (_nextStop < _stops.length && next >= _stops[_nextStop].meters) {
        // Chegou à parada: espera o embarque e o desembarque.
        next = _stops[_nextStop].meters;
        _nextStop++;
        _waiting = Duration(seconds: config.stopSeconds);
      }
      if (next >= routeLength) {
        next = routeLength;
        _waiting = _endOfLineWait;
      }
      _meters = next;
    }
    unawaited(_send());
  }

  Future<void> _send() async {
    // Uma posição por vez: se a rede atrasar, a próxima espera.
    if (_sending) return;
    _sending = true;
    final _Point position = _pointAt(_meters);
    try {
      await _database.patch('drivers/${_session.uid}', <String, Object?>{
        'latitude': position.lat,
        'longitude': position.lng,
        'status': 'trip_started',
        'updatedAt': _serverTime,
      });
      _failures = 0;
    } catch (error) {
      _failures++;
      if (_failures == 1 || _failures % 30 == 0) {
        stderr.writeln('[$label] falha ao enviar posição: $error');
      }
    } finally {
      _sending = false;
    }
  }

  /// Encerra o trajeto, como o botão "Encerrar Trajeto" do app.
  Future<void> finish() async {
    try {
      await _database.patch('drivers/${_session.uid}', <String, Object?>{
        'status': 'trip_finished',
        'finishedAt': _serverTime,
        'updatedAt': _serverTime,
      });
      stdout.writeln('[$label] trajeto encerrado.');
    } catch (error) {
      stderr.writeln('[$label] falha ao encerrar: $error');
    }
  }

  String status() {
    final int percent = (_meters / routeLength * 100).round();
    final String next = _nextStop < _stops.length
        ? 'próxima: ${_stops[_nextStop].name}'
        : 'indo para o fim da linha';
    final String state = _waiting > Duration.zero
        ? 'parado (${_waiting.inSeconds} s)'
        : 'andando';
    return '[$label] $percent% do trajeto, $state, $next';
  }

  int _stopIndexAfter(double meters) {
    int index = 0;
    while (index < _stops.length && _stops[index].meters < meters) {
      index++;
    }
    return index;
  }

  _Point _pointAt(double meters) {
    int i = 0;
    while (i < _cumulative.length - 2 && _cumulative[i + 1] < meters) {
      i++;
    }
    final double length = _cumulative[i + 1] - _cumulative[i];
    final double t =
        length <= 0 ? 0 : ((meters - _cumulative[i]) / length).clamp(0.0, 1.0);
    final _Point a = _route[i];
    final _Point b = _route[i + 1];
    return _Point(a.lat + (b.lat - a.lat) * t, a.lng + (b.lng - a.lng) * t);
  }
}

class _Point {
  const _Point(this.lat, this.lng);

  final double lat;
  final double lng;
}

/// Distância em metros entre dois pontos (haversine).
double _distanceMeters(_Point a, _Point b) {
  const double earthRadius = 6371000;
  final double lat1 = a.lat * math.pi / 180;
  final double lat2 = b.lat * math.pi / 180;
  final double dLat = lat2 - lat1;
  final double dLng = (b.lng - a.lng) * math.pi / 180;
  final double h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * earthRadius * math.asin(math.sqrt(h));
}

/// Distância (m) do início do traçado até o ponto dele mais próximo de [p].
double _project(List<_Point> route, List<double> cumulative, _Point p) {
  double bestDistance = double.infinity;
  double bestMeters = 0;
  for (int i = 0; i < route.length - 1; i++) {
    final _Point a = route[i];
    final _Point b = route[i + 1];
    final double k = math.cos(a.lat * math.pi / 180);
    final double dx = (b.lng - a.lng) * k;
    final double dy = b.lat - a.lat;
    final double lengthSq = dx * dx + dy * dy;
    final double t = lengthSq == 0
        ? 0
        : (((p.lng - a.lng) * k * dx + (p.lat - a.lat) * dy) / lengthSq)
            .clamp(0.0, 1.0);
    final _Point q = _Point(a.lat + dy * t, a.lng + (b.lng - a.lng) * t);
    final double distance = _distanceMeters(q, p);
    if (distance < bestDistance) {
      bestDistance = distance;
      bestMeters = cumulative[i] + _distanceMeters(a, q);
    }
  }
  return bestMeters;
}

/// Decodifica uma polyline do Google (precisão 5).
List<_Point> _decodePolyline(String encoded) {
  final List<_Point> points = <_Point>[];
  int index = 0;
  int lat = 0;
  int lng = 0;
  while (index < encoded.length) {
    for (int coordinate = 0; coordinate < 2; coordinate++) {
      int shift = 0;
      int result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      final int delta = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      if (coordinate == 0) {
        lat += delta;
      } else {
        lng += delta;
      }
    }
    points.add(_Point(lat / 1e5, lng / 1e5));
  }
  return points;
}
