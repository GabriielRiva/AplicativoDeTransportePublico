import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/map_constants.dart';
import '../../../core/utils/map_utils.dart';
import 'route_progress.dart';
import 'trip_camera_config.dart';

/// Desenho do ônibus sobreposto ao mapa (ver [TripMapView.busSpriteFor]).
class BusSprite {
  /// Cria o desenho com a imagem [asset] exibida com [width] dp de largura.
  const BusSprite({
    required this.asset,
    required this.width,
    this.anchor = const Offset(0.5, 0.5),
  });

  /// Imagem PNG dos assets do app.
  final String asset;

  /// Largura exibida (dp); a altura segue a proporção da imagem.
  final double width;

  /// Ponto da imagem (0..1) que fica sobre a posição do ônibus.
  final Offset anchor;
}

/// Mapa de trajeto ativo compartilhado pelo motorista e pelo passageiro.
///
/// É um widget puramente de apresentação: recebe o traçado já decodificado
/// ([route]), a posição atual do ônibus ([busPosition]) e, opcionalmente, o
/// rumo ([heading]); e desenha o mapa, as polylines de trecho percorrido e
/// restante e o marcador do ônibus. A obtenção dos dados (GPS local para o
/// motorista, Firebase para o passageiro) permanece na tela chamadora, de
/// modo que este widget nunca acessa o Firebase.
class TripMapView extends StatefulWidget {
  /// Cria o mapa de trajeto.
  const TripMapView({
    super.key,
    required this.mode,
    required this.busPosition,
    this.route = const <LatLng>[],
    this.heading,
    this.extraMarkers = const <Marker>{},
    this.busIcon,
    this.busIconForHeading,
    this.busSpriteFor,
    this.northUp = false,
    this.rotateBusIcon = true,
    this.busIconAnchor = const Offset(0.5, 0.5),
    this.mapPadding = EdgeInsets.zero,
    this.showMyLocation = false,
    this.follow = true,
    this.interpolationDuration = const Duration(seconds: 5),
    this.remainingColor = const Color(0xFF1D9E75),
    this.traveledColor = const Color(0xFF9E9E9E),
  });

  /// Modo de apresentação (turn-by-turn ou tracking).
  final TripMode mode;

  /// Última posição conhecida do ônibus. No modo motorista vem do GPS do
  /// aparelho; no modo passageiro, do Realtime Database.
  final LatLng busPosition;

  /// Traçado de rua da linha ativa, já decodificado.
  final List<LatLng> route;

  /// Rumo (bearing) em graus (0-360). Quando nulo, é calculado a partir do
  /// deslocamento entre a posição anterior e a nova (útil no passageiro,
  /// cujo GPS do ônibus não traz rumo).
  final double? heading;

  /// Marcadores adicionais (ex.: paradas), exibidos junto ao ônibus.
  final Set<Marker> extraMarkers;

  /// Ícone do ônibus. Quando nulo, usa um marcador padrão.
  final BitmapDescriptor? busIcon;

  /// Ícone do ônibus de acordo com o rumo dele (ex.: ônibus 3D renderizado
  /// em vários ângulos). Quando informado, tem prioridade sobre [busIcon].
  final BitmapDescriptor Function(double heading)? busIconForHeading;

  /// Desenho do ônibus quando a câmera acompanha o ônibus ([follow]), de
  /// acordo com o rumo dele e o rumo da câmera (graus, 0 = norte).
  ///
  /// Nesse caso o ônibus não é um marcador do mapa: ele é desenhado por
  /// cima do mapa, fixo no ponto que a câmera centraliza. Mover um
  /// marcador a cada quadro faz o Google Maps reenviar o ícone toda hora,
  /// e o ônibus pisca.
  final BusSprite Function(double heading, double cameraBearing)?
      busSpriteFor;

  /// Visão de mapa do motorista: vista de cima, com o norte para cima, em
  /// vez da navegação 3D que gira com o ônibus.
  final bool northUp;

  /// Se o ícone fica "deitado" no mapa girando com a direção da rua (ex.:
  /// ônibus visto de cima). Quando falso, o ícone fica em pé, sempre virado
  /// para a tela (ex.: ônibus 3D visto de trás, com a câmera girando junto).
  final bool rotateBusIcon;

  /// Ponto do ícone (0..1) que fica sobre a posição do ônibus.
  final Offset busIconAnchor;

  /// Margens do mapa. A câmera centraliza o ônibus no meio da área que
  /// sobra; no motorista, uma margem maior em cima deixa o ônibus mais
  /// embaixo na tela, mostrando mais da rua à frente.
  final EdgeInsets mapPadding;

  /// Exibe o ponto azul com a posição do próprio usuário (passageiro).
  final bool showMyLocation;

  /// Se a câmera deve seguir o ônibus continuamente.
  final bool follow;

  /// Duração da interpolação do marcador entre duas posições. As atualizações
  /// do passageiro chegam a cada 1 s (kGpsUpdateInterval); o padrão de 5 s
  /// é só um valor seguro para quem não informar a duração.
  /// Para o motorista (GPS frequente) passe uma duração menor.
  final Duration interpolationDuration;

  /// Cor do trecho restante da rota.
  final Color remainingColor;

  /// Cor do trecho já percorrido da rota.
  final Color traveledColor;

  @override
  State<TripMapView> createState() => _TripMapViewState();
}

class _TripMapViewState extends State<TripMapView>
    with SingleTickerProviderStateMixin {
  /// Distância máxima (km) entre a posição atual e o traçado para considerar
  /// o ônibus "sobre a rota". Acima disso, o GPS está fora da linha
  /// (localização fixa do emulador, ainda a caminho do início, imprecisão
  /// pontual) e nenhum progresso é desenhado.
  static const double _maxSnapDistanceKm = 0.3;

  /// Fração da diferença de rumo aplicada a cada quadro, para a câmera e o
  /// marcador girarem suavemente nas curvas em vez de "pularem".
  static const double _headingSmoothing = 0.15;

  /// A animação dura um pouco mais que o intervalo entre posições: a nova
  /// posição chega antes de o ônibus terminar o trecho, então ele nunca
  /// fica parado esperando por ela (eram essas paradas as "travadinhas").
  static const double _durationSlack = 1.2;

  /// Recuo (m) ignorado: o GPS oscila e às vezes manda uma posição um pouco
  /// atrás da anterior; o ônibus espera no lugar em vez de andar de ré.
  static const double _backwardToleranceMeters = 30;

  /// Salto (m) a partir do qual o ônibus é reposicionado sem animação (GPS
  /// reposicionado, nova volta em linha circular).
  static const double _jumpMeters = 1000;

  /// Distância (m) à frente usada para calcular o rumo: o ônibus começa a
  /// virar um pouco antes da esquina, como um veículo de verdade.
  static const double _headingLookAheadMeters = 15;

  /// Leituras seguidas longe da rota necessárias para o ônibus sair dela.
  /// Uma leitura isolada longe da rua costuma ser erro do GPS (sinal ruim,
  /// celular balançando): o ônibus espera no lugar em vez de sair da rota.
  static const int _offRouteConfirmations = 3;

  /// Deslocamento (m) mínimo, fora da rota, para recalcular o rumo. Abaixo
  /// disso a direção entre duas leituras é só ruído do GPS.
  static const double _minHeadingMoveMeters = 5;

  /// Intervalo mínimo entre atualizações do marcador do ônibus quando a
  /// câmera não o acompanha (~12 por segundo, o suficiente para parecer
  /// contínuo). Atualizar o marcador em todo quadro (60 por segundo) faz o
  /// Google Maps reenviar o ícone toda hora, e o ônibus pisca.
  static const Duration _markerFrameInterval = Duration(milliseconds: 80);

  GoogleMapController? _controller;
  late final AnimationController _animation;

  /// Animação livre (ônibus fora da rota ou linha sem traçado).
  late LatLng _from;
  late LatLng _to;
  double _heading = 0;

  /// Animação pela rua (ônibus sobre a rota): distância (m) do início do
  /// traçado de onde o ônibus sai e aonde ele vai. Nulas fora da rota.
  /// Andar pela distância, e não em linha reta entre duas posições, faz o
  /// ônibus contornar as curvas da rua sem cortar caminho nem dar trancos.
  double? _fromMeters;
  double? _toMeters;

  /// Distância (m) do início do traçado até cada ponto dele.
  List<double> _cumulative = const <double>[];

  /// Trecho em que o ônibus foi desenhado no último quadro (acelera a
  /// busca do próximo quadro).
  int _segmentHint = 0;

  /// Último índice da rota alcançado pelo ônibus. Mantido entre as posições
  /// para que o progresso só avance (ver [RouteProgress]).
  int _progressIndex = 0;

  /// Posição desenhada no quadro atual.
  late LatLng _display;

  /// Leituras seguidas longe da rota (ver [_offRouteConfirmations]).
  int _offRouteStreak = 0;

  /// Quando o marcador do ônibus foi atualizado pela última vez (ver
  /// [_markerFrameInterval]).
  DateTime _lastMarkerFrame = DateTime.fromMillisecondsSinceEpoch(0);

  /// Rumo desenhado (marcador e câmera), suavizado entre quadros.
  double _displayHeading = 0;

  /// Intervalo médio (ms) entre as posições recebidas, medido no aparelho.
  /// Define a duração da animação, mesmo se o GPS ou a rede atrasarem.
  late double _intervalMs;
  DateTime? _lastUpdateAt;

  /// Polylines atuais. Só são recriadas quando o ônibus muda de trecho da
  /// rota, e não a cada quadro da animação.
  Set<Polyline> _polylines = const <Polyline>{};

  /// Trecho usado para montar [_polylines] (-1 = ônibus fora da rota;
  /// nulo = precisa recalcular).
  int? _polylineKey;

  @override
  void initState() {
    super.initState();
    _intervalMs = widget.interpolationDuration.inMilliseconds.toDouble();
    _from = widget.busPosition;
    _to = widget.busPosition;
    _heading = widget.heading ?? 0;
    _displayHeading = _heading;
    _animation = AnimationController(
      vsync: this,
      duration: widget.interpolationDuration,
    )..addListener(_onTick);
    _measureRoute();
    _retarget(widget.busPosition, jump: true);
    _refresh(smoothHeading: false);
  }

  @override
  void didUpdateWidget(covariant TripMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_routeChanged(oldWidget.route, widget.route)) {
      _progressIndex = 0;
      _polylineKey = null;
      _measureRoute();
      _retarget(widget.busPosition, jump: true);
      _refresh(smoothHeading: false);
      // O traçado pode chegar depois do mapa (carregado do Firebase).
      if (oldWidget.route.isEmpty) _fitRoute();
    } else if (oldWidget.busPosition != widget.busPosition) {
      _animation.duration = _nextDuration();
      _retarget(widget.busPosition);
      _animation
        ..reset()
        ..forward();
    } else if (widget.heading != null) {
      _heading = widget.heading!;
    }
    if (oldWidget.northUp != widget.northUp) _followCamera();
  }

  void _onTick() {
    if (!_usesSprite) {
      final DateTime now = DateTime.now();
      final bool lastFrame = _animation.value >= 1;
      if (!lastFrame &&
          now.difference(_lastMarkerFrame) < _markerFrameInterval) {
        return;
      }
      _lastMarkerFrame = now;
    }
    setState(_refresh);
    _followCamera();
  }

  /// Se o ônibus é desenhado por cima do mapa (ver busSpriteFor).
  bool get _usesSprite => widget.follow && widget.busSpriteFor != null;

  /// Rumo da câmera: só a navegação 3D do motorista gira com o ônibus.
  double get _cameraBearing =>
      widget.mode == TripMode.driver && !widget.northUp ? _displayHeading : 0;

  /// Centraliza a câmera no ônibus (quando [TripMapView.follow]).
  void _followCamera() {
    if (!widget.follow) return;
    _controller?.moveCamera(
      CameraUpdate.newCameraPosition(
        TripCameraConfig.forMode(
          widget.mode,
          position: _display,
          heading: _displayHeading,
          northUp: widget.northUp,
        ),
      ),
    );
  }

  /// Atualiza o intervalo médio com o tempo desde a posição anterior e
  /// devolve a duração da próxima animação.
  Duration _nextDuration() {
    final DateTime now = DateTime.now();
    final DateTime? last = _lastUpdateAt;
    _lastUpdateAt = now;
    if (last != null) {
      final int measured = now.difference(last).inMilliseconds;
      // Pausas longas (ônibus parado, app em segundo plano) não entram.
      if (measured >= 200 && measured <= 6000) {
        _intervalMs = _intervalMs * 0.7 + measured * 0.3;
      }
    }
    return Duration(milliseconds: (_intervalMs * _durationSlack).round());
  }

  /// Prepara a animação do ponto desenhado agora até [target]. Com
  /// [jump], o ônibus vai direto para [target].
  void _retarget(LatLng target, {bool jump = false}) {
    final List<LatLng> route = widget.route;
    final double? startMeters = jump ? null : _currentMeters();
    if (route.length >= 2) {
      final int index = RouteProgress.advance(
        route,
        target,
        fromIndex: _progressIndex,
      );
      final RouteSnap snap = RouteProgress.snap(route, target, index);
      if (MapUtils.distanceInKm(target, snap.point) <= _maxSnapDistanceKm) {
        _offRouteStreak = 0;
        _progressIndex = index;
        double toMeters = _metersAt(snap);
        double fromMeters = startMeters ?? toMeters;
        final double delta = toMeters - fromMeters;
        if (delta < 0 && -delta <= _backwardToleranceMeters) {
          toMeters = fromMeters;
        } else if (delta < 0 || delta > _jumpMeters) {
          fromMeters = toMeters;
        }
        _fromMeters = fromMeters;
        _toMeters = toMeters;
        return;
      }
      _offRouteStreak++;
      if (startMeters != null && _offRouteStreak < _offRouteConfirmations) {
        _fromMeters = startMeters;
        _toMeters = startMeters;
        return;
      }
    }
    final LatLng start = jump ? target : _display;
    _fromMeters = null;
    _toMeters = null;
    _from = start;
    _to = target;
    if (widget.heading != null) {
      _heading = widget.heading!;
    } else if (MapUtils.distanceInKm(start, target) * 1000 >
        _minHeadingMoveMeters) {
      _heading = _bearing(start, target);
    }
  }

  /// Distância (m) do início do traçado na animação pela rua, ou nula se o
  /// ônibus está fora da rota.
  double? _currentMeters() {
    final double? from = _fromMeters;
    final double? to = _toMeters;
    if (from == null || to == null) return null;
    return from + (to - from) * _animation.value;
  }

  void _measureRoute() {
    final List<LatLng> route = widget.route;
    final List<double> cumulative = List<double>.filled(route.length, 0);
    for (int i = 1; i < route.length; i++) {
      cumulative[i] = cumulative[i - 1] +
          MapUtils.distanceInKm(route[i - 1], route[i]) * 1000;
    }
    _cumulative = cumulative;
    _segmentHint = 0;
  }

  double _metersAt(RouteSnap snap) {
    return _cumulative[snap.segmentStart] +
        MapUtils.distanceInKm(widget.route[snap.segmentStart], snap.point) *
            1000;
  }

  /// Ponto do traçado a [meters] do início e o trecho em que ele está.
  ({LatLng point, int segment}) _pointAt(double meters) {
    final List<LatLng> route = widget.route;
    final List<double> c = _cumulative;
    final int last = c.length - 2;
    int i = math.max(0, math.min(_segmentHint, last));
    while (i > 0 && c[i] > meters) {
      i--;
    }
    while (i < last && c[i + 1] <= meters) {
      i++;
    }
    final double length = c[i + 1] - c[i];
    final double t =
        length <= 0 ? 0 : ((meters - c[i]) / length).clamp(0.0, 1.0);
    final LatLng a = route[i];
    final LatLng b = route[i + 1];
    return (
      point: LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      ),
      segment: i,
    );
  }

  /// Recalcula posição desenhada, rumo e (se o trecho mudou) as polylines
  /// para o quadro atual da animação.
  void _refresh({bool smoothHeading = true}) {
    final double? meters = _currentMeters();
    double targetHeading = _heading;

    if (meters != null &&
        widget.route.length >= 2 &&
        _cumulative.length == widget.route.length) {
      final ({LatLng point, int segment}) here = _pointAt(meters);
      _segmentHint = here.segment;
      _display = here.point;
      final LatLng ahead = _pointAt(meters + _headingLookAheadMeters).point;
      if (MapUtils.distanceInKm(here.point, ahead) * 1000 > 1) {
        targetHeading = _bearing(here.point, ahead);
      } else {
        // Fim do traçado: mantém o rumo atual.
        targetHeading = _displayHeading;
      }
      _setPolylines(here.segment);
    } else {
      final double t = _animation.value;
      _display = LatLng(
        _from.latitude + (_to.latitude - _from.latitude) * t,
        _from.longitude + (_to.longitude - _from.longitude) * t,
      );
      _setPolylines(null);
    }

    _displayHeading = smoothHeading
        ? _lerpAngle(_displayHeading, targetHeading, _headingSmoothing)
        : targetHeading;
  }

  /// O traçado inteiro fica sempre desenhado como "restante" e o trecho
  /// percorrido é desenhado por cima. Assim, quando o ônibus muda de
  /// trecho, só a linha cinza é reenviada ao mapa, não as duas.
  void _setPolylines(int? segmentStart) {
    final int key = segmentStart ?? -1;
    if (key == _polylineKey) return;
    _polylineKey = key;

    final List<LatLng> route = widget.route;
    if (route.length < 2) {
      _polylines = const <Polyline>{};
      return;
    }
    final Polyline remaining = Polyline(
      polylineId: const PolylineId('route_remaining'),
      points: route,
      color: widget.remainingColor,
      width: 6,
    );
    if (segmentStart == null || segmentStart < 1) {
      _polylines = <Polyline>{remaining};
      return;
    }
    _polylines = <Polyline>{
      remaining,
      Polyline(
        polylineId: const PolylineId('route_traveled'),
        points: route.sublist(0, segmentStart + 1),
        color: widget.traveledColor,
        width: 6,
        zIndex: 1,
      ),
    };
  }

  double _bearing(LatLng a, LatLng b) {
    final double lat1 = a.latitude * math.pi / 180;
    final double lat2 = b.latitude * math.pi / 180;
    final double dLon = (b.longitude - a.longitude) * math.pi / 180;
    final double y = math.sin(dLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  /// Interpola ângulos pelo menor caminho (ex.: de 350° para 10° passa por
  /// 0°, e não por 180°).
  double _lerpAngle(double from, double to, double t) {
    final double delta = ((to - from + 540) % 360) - 180;
    return (from + delta * t + 360) % 360;
  }

  /// Compara de forma barata (tamanho e extremidades) se o traçado mudou,
  /// para reiniciar o progresso ao trocar de linha.
  bool _routeChanged(List<LatLng> previous, List<LatLng> current) {
    if (previous.length != current.length) return true;
    if (current.isEmpty) return false;
    return previous.first != current.first || previous.last != current.last;
  }

  Set<Marker> _buildMarkers() {
    return <Marker>{
      ...widget.extraMarkers,
      if (!_usesSprite)
        Marker(
          markerId: const MarkerId('active_bus'),
          position: _display,
          rotation: widget.rotateBusIcon ? _displayHeading : 0,
          flat: widget.rotateBusIcon,
          anchor: widget.busIconAnchor,
          icon: widget.busIconForHeading?.call(_displayHeading) ??
              widget.busIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
        ),
    };
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _fitRoute();
  }

  /// Sem acompanhar o ônibus ([TripMapView.follow] falso), enquadra o
  /// trajeto inteiro e a posição do ônibus na tela.
  void _fitRoute() {
    if (widget.follow || widget.route.isEmpty) return;
    _controller?.animateCamera(
      CameraUpdate.newLatLngBounds(
        MapUtils.boundsFromPoints(<LatLng>[
          ...widget.route,
          widget.busPosition,
        ]),
        48,
      ),
    );
  }

  @override
  void dispose() {
    _animation.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GoogleMap map = GoogleMap(
      initialCameraPosition: TripCameraConfig.forMode(
        widget.mode,
        position: _display,
        heading: _displayHeading,
        northUp: widget.northUp,
      ),
      onMapCreated: _onMapCreated,
      padding: widget.mapPadding,
      polylines: _polylines,
      markers: _buildMarkers(),
      myLocationEnabled: widget.showMyLocation,
      myLocationButtonEnabled: false,
      // A bússola do Google Maps brigava com a câmera que acompanha o
      // ônibus (voltava sozinha para o 3D e às vezes sumia). A troca entre
      // 3D e mapa é feita por um botão próprio na tela do motorista.
      compassEnabled: false,
      // Com a câmera acompanhando o ônibus, ela é reposicionada a cada
      // quadro; arrastar ou girar o mapa não teria efeito.
      scrollGesturesEnabled: !widget.follow,
      rotateGesturesEnabled: !widget.follow,
      tiltGesturesEnabled: !widget.follow,
      zoomGesturesEnabled: !widget.follow,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      // Trava a câmera dentro de Chapecó, igual ao BusMap — evita o
      // trajeto "fugir" pra fora da área de cobertura (ex.: localização
      // padrão do emulador Android, que cai no Googleplex em Mountain
      // View) aparecendo no mapa do motorista/passageiro.
      cameraTargetBounds: CameraTargetBounds(kChapecoBounds),
      minMaxZoomPreference: const MinMaxZoomPreference(kMinZoom, kMaxZoom),
    );
    if (!_usesSprite) return map;

    final BusSprite sprite =
        widget.busSpriteFor!(_displayHeading, _cameraBearing);
    final EdgeInsets padding = widget.mapPadding;
    return Stack(
      children: <Widget>[
        map,
        // A câmera centraliza o ônibus no meio da área do mapa que sobra
        // depois das margens: é ali que ele é desenhado.
        Positioned.fill(
          child: IgnorePointer(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double x = padding.left +
                    (constraints.maxWidth - padding.horizontal) / 2;
                final double y = padding.top +
                    (constraints.maxHeight - padding.vertical) / 2;
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: x,
                      top: y,
                      child: FractionalTranslation(
                        translation: Offset(
                          -sprite.anchor.dx,
                          -sprite.anchor.dy,
                        ),
                        child: Image.asset(
                          sprite.asset,
                          width: sprite.width,
                          gaplessPlayback: true,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
