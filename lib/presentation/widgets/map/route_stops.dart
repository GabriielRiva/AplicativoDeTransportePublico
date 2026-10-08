import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/map_utils.dart';
import '../../../domain/entities/stop.dart';
import 'route_progress.dart';

/// Parada à frente do ônibus e a distância (m) até ela pela rota.
typedef StopAhead = ({Stop stop, double meters});

/// Paradas de uma linha posicionadas ao longo do traçado, para medir
/// distâncias pela rua (e não em linha reta) e saber qual é a próxima
/// parada à frente do ônibus.
///
/// Cada parada é procurada no traçado a partir da anterior, na ordem da
/// linha. Assim, em linhas que vão e voltam pela mesma rua, a parada da
/// volta não é confundida com a da ida.
class RouteStops {
  RouteStops._(
    this.route,
    this.stops,
    this._cumulative,
    this._stopMeters,
    this.isCircular,
  );

  /// Posiciona as [stops] (em qualquer ordem) ao longo de [route].
  factory RouteStops(List<LatLng> route, List<Stop> stops) {
    final List<Stop> ordered = <Stop>[...stops]
      ..sort((Stop a, Stop b) => a.order.compareTo(b.order));

    final List<double> cumulative = List<double>.filled(route.length, 0);
    for (int i = 1; i < route.length; i++) {
      cumulative[i] = cumulative[i - 1] + _meters(route[i - 1], route[i]);
    }

    final List<double> stopMeters = <double>[];
    int from = 0;
    for (final Stop stop in ordered) {
      if (route.isEmpty) {
        stopMeters.add(0);
        continue;
      }
      final int index =
          _indexOf(route, LatLng(stop.latitude, stop.longitude), from);
      stopMeters.add(cumulative[index]);
      from = index;
    }

    final bool circular = route.length > 2 &&
        _meters(route.first, route.last) <= _circularToleranceMeters;
    return RouteStops._(route, ordered, cumulative, stopMeters, circular);
  }

  /// Distância (m) entre o início e o fim do traçado abaixo da qual a
  /// linha é considerada circular (termina onde começa).
  static const double _circularToleranceMeters = 150;

  /// Distância (m) até o traçado para considerar que ele passa pela parada.
  static const double _matchRadiusMeters = 60;

  /// Afastamento (m) depois do ponto mais próximo que encerra a busca.
  static const double _leaveMeters = 150;

  /// Traçado da linha.
  final List<LatLng> route;

  /// Paradas na ordem da linha.
  final List<Stop> stops;

  /// Indica se a linha termina onde começa (ex.: sai e volta ao Terminal).
  final bool isCircular;

  /// Distância (m) do início do traçado até cada ponto dele.
  final List<double> _cumulative;

  /// Distância (m) do início do traçado até cada parada de [stops].
  final List<double> _stopMeters;

  /// Comprimento total do traçado (m).
  double get totalMeters => _cumulative.isEmpty ? 0 : _cumulative.last;

  /// Distância (m) pela rua do início do traçado até cada parada de
  /// [stops], na mesma ordem.
  List<double> get stopMeters => List<double>.unmodifiable(_stopMeters);

  /// Quantos pontos o ônibus, a [busMeters] do início, ainda passa nos
  /// próximos [distance] metros, sem contar o ponto em que já está nem o
  /// ponto de destino (usado para somar o tempo parado em cada um).
  int stopsOnTheWay(double busMeters, double distance) {
    int count = 0;
    for (final double stopAt in _stopMeters) {
      double ahead = stopAt - busMeters;
      if (ahead < -kStopArrivalRadiusMeters && isCircular) {
        ahead += totalMeters;
      }
      if (ahead > kStopArrivalRadiusMeters &&
          ahead < distance - kStopArrivalRadiusMeters) {
        count++;
      }
    }
    return count;
  }

  /// Distância (m) do início do traçado até a posição [snap] do ônibus.
  double metersAt(RouteSnap snap) {
    return _cumulative[snap.segmentStart] +
        _meters(route[snap.segmentStart], snap.point);
  }

  /// Próxima parada à frente do ônibus, que está a [busMeters] do início.
  /// Paradas a menos de [kStopArrivalRadiusMeters] contam como a parada em
  /// que o ônibus já está, e a seguinte é retornada. Em linhas circulares,
  /// depois da última parada vem de novo a primeira.
  StopAhead? nextStop(double busMeters) {
    for (int i = 0; i < stops.length; i++) {
      final double meters = _stopMeters[i] - busMeters;
      if (meters > kStopArrivalRadiusMeters) {
        return (stop: stops[i], meters: meters);
      }
    }
    if (isCircular) {
      for (int i = 0; i < stops.length; i++) {
        final double meters = totalMeters - busMeters + _stopMeters[i];
        if (meters > kStopArrivalRadiusMeters) {
          return (stop: stops[i], meters: meters);
        }
      }
    }
    return null;
  }

  /// Distância (m) pela rota do ônibus, a [busMeters] do início, até a
  /// parada [stop]. Nula se o ônibus já passou por ela e a linha não é
  /// circular (ele não vai mais passar ali neste trajeto).
  double? metersTo(Stop stop, double busMeters) {
    final int i = stops.indexWhere((Stop s) => s.id == stop.id);
    if (i < 0) return null;
    final double meters = _stopMeters[i] - busMeters;
    if (meters >= -kStopArrivalRadiusMeters) return math.max(0.0, meters);
    if (isCircular) return totalMeters - busMeters + _stopMeters[i];
    return null;
  }

  /// Índice do ponto de [route] por onde o traçado passa por [point],
  /// procurando a partir de [from]: a primeira aproximação a até
  /// [_matchRadiusMeters], ou o ponto mais próximo se nenhuma chegar perto.
  static int _indexOf(List<LatLng> route, LatLng point, int from) {
    int best = from;
    double bestMeters = double.infinity;
    for (int k = from; k < route.length; k++) {
      final double meters = _meters(route[k], point);
      if (meters < bestMeters) {
        bestMeters = meters;
        best = k;
      } else if (bestMeters <= _matchRadiusMeters &&
          meters > bestMeters + _leaveMeters) {
        break;
      }
    }
    return best;
  }

  static double _meters(LatLng a, LatLng b) =>
      MapUtils.distanceInKm(a, b) * 1000;
}

/// Acompanha a posição de um ônibus ao longo da rota, sempre para a frente
/// (ver [RouteProgress.advance]).
class RouteTracker {
  int _index = 0;

  /// Posição de [position] sobre [route], ou nula se o ônibus está fora da
  /// rota (a mais de [RouteProgress.defaultMaxDistanceKm] dela).
  RouteSnap? locate(List<LatLng> route, LatLng position) {
    if (route.length < 2) return null;
    _index = RouteProgress.advance(route, position, fromIndex: _index);
    final RouteSnap snap = RouteProgress.snap(route, position, _index);
    final double offRouteKm = MapUtils.distanceInKm(snap.point, position);
    if (offRouteKm > RouteProgress.defaultMaxDistanceKm) return null;
    return snap;
  }
}
