import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Zoom inicial da câmera ao abrir o mapa (mais próximo do centro).
const double kGoogleMapsZoom = 15.5;

/// Zoom aplicado ao focar em um ônibus específico.
const double kBusFocusZoom = 16;

/// Zoom mínimo: impede afastar demais (perder Chapecó de vista).
const double kMinZoom = 12.5;

/// Zoom máximo útil.
const double kMaxZoom = 20;

/// Centro geográfico de Chapecó-SC (posição inicial da câmera).
const LatLng kChapecoCenter = LatLng(-27.1004, -52.6152);

/// Limites geográficos da área urbana de Chapecó-SC.
final LatLngBounds kChapecoBounds = LatLngBounds(
  southwest: const LatLng(-27.17, -52.72),
  northeast: const LatLng(-27.03, -52.55),
);

/// Largura da polyline que desenha a rota da linha.
const int kRoutePolylineWidth = 5;