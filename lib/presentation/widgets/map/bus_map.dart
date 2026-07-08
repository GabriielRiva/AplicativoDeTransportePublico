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

  /// Exibe o ponto azul da posição do usuário.
  final bool myLocationEnabled;

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialTarget,
        zoom: initialZoom,
      ),
      markers: markers,
      polylines: polylines,
      onMapCreated: onMapCreated,
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: myLocationEnabled,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }
}
