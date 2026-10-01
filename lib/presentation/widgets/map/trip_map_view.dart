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
  /// Distância máxima (km) entre a posição atual e o ponto mais próximo da
  /// rota para considerar o ônibus "sobre o traçado". Acima disso, o GPS
  /// está fora da rota (localização fixa do emulador, ainda a caminho do
  /// início da linha, imprecisão pontual) e nenhum progresso é desenhado.
  static const double _maxSnapDistanceKm = 0.3;

  GoogleMapController? _controller;
  late final AnimationController _animation;
  late LatLng _from;
  late LatLng _to;
  double _heading = 0;

  /// Último índice da rota alcançado pelo ônibus. Mantido entre os quadros
  /// para que a divisão percorrido/restante só avance (ver [RouteProgress]).
  int _progressIndex = 0;

  @override
  void initState() {
    super.initState();
    _from = widget.busPosition;
    _to = widget.busPosition;
    _heading = widget.heading ?? 0;
    _animation = AnimationController(
      vsync: this,
      duration: widget.interpolationDuration,
    )..addListener(_onTick);
  }

  @override
  void didUpdateWidget(covariant TripMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_routeChanged(oldWidget.route, widget.route)) {
      _progressIndex = 0;
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
  }

  void _onTick() {
    setState(() {});
    if (widget.follow) {
      _controller?.moveCamera(
        CameraUpdate.newCameraPosition(
          TripCameraConfig.forMode(
            widget.mode,
            position: _currentPosition(),
            heading: _heading,
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

  double _bearing(LatLng a, LatLng b) {
    final double lat1 = a.latitude * math.pi / 180;
    final double lat2 = b.latitude * math.pi / 180;
    final double dLon = (b.longitude - a.longitude) * math.pi / 180;
    final double y = math.sin(dLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  /// Compara de forma barata (tamanho e extremidades) se o traçado mudou,
  /// para reiniciar o progresso ao trocar de linha.
  bool _routeChanged(List<LatLng> previous, List<LatLng> current) {
    if (previous.length != current.length) return true;
    if (current.isEmpty) return false;
    return previous.first != current.first || previous.last != current.last;
  }

  Set<Polyline> _buildPolylines(LatLng position) {
    if (widget.route.isEmpty) return const <Polyline>{};
    final int splitIndex = RouteProgress.advance(
      widget.route,
      position,
      fromIndex: _progressIndex,
    );

    // Ônibus fora do traçado (GPS ainda longe do início da linha, posição
    // fixa do emulador, desvio): não há progresso a mostrar. Desenha a rota
    // inteira como "restante" e mantém o último progresso conhecido, em vez
    // de pintar parte da rota de cinza nem ligar o marcador à rota com uma
    // linha reta cortando quarteirões.
    final bool onRoute =
        MapUtils.distanceInKm(position, widget.route[splitIndex]) <=
            _maxSnapDistanceKm;
    if (!onRoute) {
      return <Polyline>{
        Polyline(
          polylineId: const PolylineId('route_remaining'),
          points: widget.route,
          color: widget.remainingColor,
          width: 6,
        ),
      };
    }
    _progressIndex = splitIndex;

    final List<LatLng> traveled = <LatLng>[
      ...widget.route.sublist(0, splitIndex + 1),
      position,
    ];
    final List<LatLng> remaining = <LatLng>[
      position,
      ...widget.route.sublist(splitIndex),
    ];
    return <Polyline>{
      Polyline(
        polylineId: const PolylineId('route_traveled'),
        points: traveled,
        color: widget.traveledColor,
        width: 5,
      ),
      Polyline(
        polylineId: const PolylineId('route_remaining'),
        points: remaining,
        color: widget.remainingColor,
        width: 6,
      ),
    };
  }

  Set<Marker> _buildMarkers(LatLng position) {
    return <Marker>{
      ...widget.extraMarkers,
      Marker(
        markerId: const MarkerId('active_bus'),
        position: position,
        rotation: _heading,
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
    final LatLng position = _currentPosition();
    return GoogleMap(
      initialCameraPosition: TripCameraConfig.forMode(
        widget.mode,
        position: widget.busPosition,
        heading: _heading,
      ),
      onMapCreated: _onMapCreated,
      polylines: _buildPolylines(position),
      markers: _buildMarkers(position),
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
