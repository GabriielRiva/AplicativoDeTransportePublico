import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/trip.dart';
import '../../domain/usecases/passenger/watch_active_buses.dart';
import 'auth_providers.dart';
import 'usecase_providers.dart';

/// Stream em tempo real dos ônibus em circulação (RF07/RF12/RF18).
///
/// Observa a sessão para recriar a stream a cada login/logout,
/// evitando que um erro de permissão pós-logout fique retido.
///
/// Ônibus sem posição nova há mais de [kBusStaleAfter] somem da lista,
/// mesmo que o banco não mude (conferido a cada [kBusStaleCheckInterval]).
final StreamProvider<List<Trip>> activeBusesProvider =
    StreamProvider<List<Trip>>((Ref ref) {
  ref.watch(authStateProvider);
  return _withoutStaleBuses(ref.watch(watchActiveBusesProvider).call());
});

/// Repassa [source] sem os ônibus parados há mais de [kBusStaleAfter] e
/// emite de novo quando um ônibus "vence", sem esperar o banco mudar.
Stream<List<Trip>> _withoutStaleBuses(Stream<List<Trip>> source) {
  List<Trip> latest = const <Trip>[];
  Set<String> shown = const <String>{};
  StreamSubscription<List<Trip>>? subscription;
  Timer? timer;
  late final StreamController<List<Trip>> controller;

  List<Trip> fresh() =>
      WatchActiveBuses.withoutStale(latest, DateTime.now());

  void emit(List<Trip> trips) {
    shown = trips.map((Trip trip) => trip.id).toSet();
    controller.add(trips);
  }

  controller = StreamController<List<Trip>>(
    onListen: () {
      subscription = source.listen(
        (List<Trip> trips) {
          latest = trips;
          emit(fresh());
        },
        onError: controller.addError,
      );
      timer = Timer.periodic(kBusStaleCheckInterval, (_) {
        final List<Trip> trips = fresh();
        final Set<String> ids = trips.map((Trip trip) => trip.id).toSet();
        if (!setEquals(ids, shown)) emit(trips);
      });
    },
    onCancel: () async {
      timer?.cancel();
      await subscription?.cancel();
    },
  );
  return controller.stream;
}
