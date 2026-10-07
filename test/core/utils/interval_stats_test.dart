import 'package:flutter_test/flutter_test.dart';
import 'package:trancity/core/utils/interval_stats.dart';

void main() {
  group('IntervalStats', () {
    test('sem intervalos tudo fica zerado', () {
      final IntervalStats stats = IntervalStats.of(const <int>[]);
      expect(stats.count, 0);
      expect(stats.allWithinLimit, isFalse);
    });

    test('calcula média, mínimo, máximo e percentual dentro do limite', () {
      final IntervalStats stats =
          IntervalStats.of(const <int>[1000, 1200, 800, 6000]);
      expect(stats.count, 4);
      expect(stats.meanMs, 2250);
      expect(stats.minMs, 800);
      expect(stats.maxMs, 6000);
      expect(stats.withinLimitPercent, 75);
      expect(stats.allWithinLimit, isFalse);
    });

    test('percentil 95 pelo posto mais próximo', () {
      final IntervalStats stats = IntervalStats.of(
        <int>[for (int i = 1; i <= 100; i++) i * 10],
      );
      expect(stats.p95Ms, 950);
    });

    test('todos dentro de 5 s atende o RNF05', () {
      final IntervalStats stats =
          IntervalStats.of(const <int>[990, 1010, 1000, 5000]);
      expect(stats.allWithinLimit, isTrue);
      expect(stats.withinLimitPercent, 100);
    });
  });
}
