import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/line.dart';
import '../../domain/entities/schedule.dart';
import '../../domain/entities/stop.dart';
import 'usecase_providers.dart';

/// Linhas cadastradas no sistema, ordenadas por número (RF08).
final FutureProvider<List<Line>> linesProvider =
    FutureProvider<List<Line>>((Ref ref) {
  return ref.watch(getLinesProvider).call();
});

/// Paradas de uma linha, ordenadas pela sequência da rota (RF09).
final FutureProviderFamily<List<Stop>, String> lineStopsProvider =
    FutureProvider.family<List<Stop>, String>((Ref ref, String lineId) {
  return ref.watch(getLineStopsProvider).call(lineId);
});

/// Horários de saída de uma linha (RF10).
final FutureProviderFamily<List<Schedule>, String> lineSchedulesProvider =
    FutureProvider.family<List<Schedule>, String>(
        (Ref ref, String lineId) {
  return ref.watch(getLineSchedulesProvider).call(lineId);
});
