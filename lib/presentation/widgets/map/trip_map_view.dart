import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/map_constants.dart';
import '../../../core/utils/map_utils.dart';
import 'route_progress.dart';
import 'trip_camera_config.dart';

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

  /// Se a câmera deve seguir o ônibus continuamente.
  final bool follow;

  /// Duração da interpolação do marcador entre duas posições. As atualizações
  /// do passageiro chegam a cada 5s, então o padrão evita o "teletransporte".
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

  GoogleMapController? _controller;
  late final AnimationController _animation;
  late LatLng _from;
  late LatLng _to;
  double _heading = 0;

  /// Último índice da rota alcançado pelo ônibus. Mantido entre os quadros
  /// para que a divisão percorrido/restante só avance (ver [RouteProgress]).
  int _progressIndex = 0;

  /// Posição desenhada: projetada sobre a rua quando o ônibus está na rota,
  /// ou a posição do GPS quando está fora dela.
  late LatLng _display;

  /// Rumo desenhado (marcador e câmera), suavizado entre quadros.
  double _displayHeading = 0;

  /// Polylines atuais. Só são recriadas quando o ônibus muda de trecho da
  /// rota, e não a cada quadro da animação: reenviar centenas de pontos ao
  /// mapa nativo 60 vezes por segundo deixava o mapa travado.
  Set<Polyline> _polylines = const <Polyline>{};

  /// Trecho usado para montar [_polylines] (-1 = ônibus fora da rota;
  /// nulo = precisa recalcular).
  int? _polylineKey;

  @override
  void initState() {
    super.initState();
    _from = widget.busPosition;
    _to = widget.busPosition;
    _heading = widget.heading ?? 0;
    _displayHeading = _heading;
    _animation = AnimationController(
      vsync: this,
      duration: widget.interpolationDuration,
    )..addListener(_onTick);
    _refresh(smoothHeading: false);
  }

  @override
  void didUpdateWidget(covariant TripMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool routeChanged = _routeChanged(oldWidget.route, widget.route);
    if (routeChanged) {
      _progressIndex = 0;
      _polylineKey = null;
    }
    if (oldWidget.busPosition != widget.busPosition) {
      final LatLng start = _currentPosition();
      _heading = widget.heading ?? _bearing(start, widget.busPosition);
      _from = start;
      _to = widget.busPosition;
      _animation
        ..reset()
        ..forward();
    } else if (widget.heading != null) {
      _heading = widget.heading!;
    }
    if (routeChanged) _refresh(smoothHeading: false);
  }

  void _onTick() {
    setState(_refresh);
    if (widget.follow) {
      _controller?.moveCamera(
        CameraUpdate.newCameraPosition(
          TripCameraConfig.forMode(
            widget.mode,
            position: _display,
            heading: _displayHeading,
          ),
        ),
      );
    }
  }

  LatLng _currentPosition() {
    final double t = _animation.value;
    return LatLng(
      _from.latitude + (_to.latitude - _from.latitude) * t,
      _from.longitude + (_to.longitude - _from.longitude) * t,
    );
  }

  /// Recalcula posição desenhada, rumo e (se o trecho mudou) as polylines a
  /// partir da posição interpolada atual.
  void _refresh({bool smoothHeading = true}) {
    final LatLng raw = _currentPosition();
    final List<LatLng> route = widget.route;
    double targetHeading = _heading;

    if (route.length < 2) {
      _display = raw;
      _setPolylines(null);
    } else {
      final int index = RouteProgress.advance(
        route,
        raw,
        fromIndex: _progressIndex,
      );
      final RouteSnap snap = RouteProgress.snap(route, raw, index);
      final bool onRoute =
          MapUtils.distanceInKm(raw, snap.point) <= _maxSnapDistanceKm;
      if (onRoute) {
        // Sobre a rota: o ônibus é desenhado em cima da rua e aponta na
        // direção do trecho em que está.
        _progressIndex = index;
        _display = snap.point;
        targetHeading = _bearing(
          route[snap.segmentStart],
          route[snap.segmentStart + 1],
        );
        _setPolylines(snap.segmentStart);
      } else {
        // Fora da rota: mostra a posição real e a rota inteira como
        // "restante", mantendo o último progresso conhecido.
        _display = raw;
        _setPolylines(null);
      }
    }

    _displayHeading = smoothHeading
        ? _lerpAngle(_displayHeading, targetHeading, _headingSmoothing)
        : targetHeading;
  }

  void _setPolylines(int? segmentStart) {
    final int key = segmentStart ?? -1;
    if (key == _polylineKey) return;
    _polylineKey = key;

    final List<LatLng> route = widget.route;
    if (route.length < 2) {
      _polylines = const <Polyline>{};
    } else if (segmentStart == null) {
      _polylines = <Polyline>{
        Polyline(
          polylineId: const PolylineId('route_remaining'),
          points: route,
          color: widget.remainingColor,
          width: 6,
        ),
      };
    } else {
      _polylines = <Polyline>{
        Polyline(
          polylineId: const PolylineId('route_traveled'),
          points: route.sublist(0, segmentStart + 1),
          color: widget.traveledColor,
          width: 5,
        ),
        Polyline(
          polylineId: const PolylineId('route_remaining'),
          points: route.sublist(segmentStart),
          color: widget.remainingColor,
          width: 6,
        ),
      };
    }
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
      Marker(
        markerId: const MarkerId('active_bus'),
        position: _display,
        rotation: _displayHeading,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        icon: widget.busIcon ??
            BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
      ),
    };
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    if (!widget.follow && widget.route.isNotEmpty) {
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          MapUtils.boundsFromPoints(widget.route),
          48,
        ),
      );
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: TripCameraConfig.forMode(
        widget.mode,
        position: _display,
        heading: _displayHeading,
      ),
      onMapCreated: _onMapCreated,
      polylines: _polylines,
      markers: _buildMarkers(),
      myLocationEnabled: false,
      compassEnabled: widget.mode == TripMode.driver,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      // Trava a câmera dentro de Chapecó, igual ao BusMap — evita o
      // trajeto "fugir" pra fora da área de cobertura (ex.: localização
      // padrão do emulador Android, que cai no Googleplex em Mountain
      // View) aparecendo no mapa do motorista/passageiro.
      cameraTargetBounds: CameraTargetBounds(kChapecoBounds),
      minMaxZoomPreference: const MinMaxZoomPreference(kMinZoom, kMaxZoom),
    );
  }
}
