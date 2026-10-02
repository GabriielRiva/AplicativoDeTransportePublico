import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/map_constants.dart';

/// Wrapper do Google Maps usado em todas as telas com mapa (RF11).
class BusMap extends StatelessWidget {
  /// Cria o mapa com [markers] e [polylines] opcionais.
  const BusMap({
    super.key,
    this.markers = const <Marker>{},
    this.polylines = const <Polyline>{},
    this.initialTarget = kChapecoCenter,
    this.initialZoom = kGoogleMapsZoom,
    this.onMapCreated,
    this.onTap,
    this.initialTilt = 0,
    this.rotateGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
    this.myLocationEnabled = true,
  });

  /// Marcadores exibidos no mapa.
  final Set<Marker> markers;

  /// Rotas desenhadas no mapa.
  final Set<Polyline> polylines;

  /// Posição inicial da câmera.
  final LatLng initialTarget;

  /// Zoom inicial da câmera.
  final double initialZoom;

  /// Callback com o controlador do mapa.
  final void Function(GoogleMapController)? onMapCreated;

  /// Toque em uma área vazia do mapa.
  final void Function(LatLng)? onTap;

  /// Inclinação inicial da câmera (0 = vista de cima). Com inclinação e
  /// zoom alto o Google Maps mostra os prédios em 3D.
  final double initialTilt;

  /// Permite girar o mapa com dois dedos.
  final bool rotateGesturesEnabled;

  /// Permite mudar a inclinação com dois dedos.
  final bool tiltGesturesEnabled;

  /// Exibe o ponto azul da posição do usuário.
  final bool myLocationEnabled;

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialTarget,
        zoom: initialZoom,
        tilt: initialTilt,
      ),
      markers: markers,
      polylines: polylines,
      onMapCreated: onMapCreated,
      onTap: onTap,
      rotateGesturesEnabled: rotateGesturesEnabled,
      tiltGesturesEnabled: tiltGesturesEnabled,
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: myLocationEnabled,
      // Trava a câmera dentro de Chapecó e limita o zoom.
      cameraTargetBounds: CameraTargetBounds(kChapecoBounds),
      minMaxZoomPreference: const MinMaxZoomPreference(kMinZoom, kMaxZoom),
      zoomGesturesEnabled: true,
      // Botões +/- ajudam no zoom pelo emulador (sem pinça no mouse).
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
    );
  }
}