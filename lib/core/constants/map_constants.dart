import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Zoom inicial da câmera ao abrir o mapa.
const double kGoogleMapsZoom = 14;

/// Zoom aplicado ao focar em um ônibus específico.
const double kBusFocusZoom = 16;

/// Centro geográfico de Chapecó-SC (posição inicial da câmera).
const LatLng kChapecoCenter = LatLng(-27.1004, -52.6152);

/// Largura da polyline que desenha a rota da linha.
const int kRoutePolylineWidth = 5;