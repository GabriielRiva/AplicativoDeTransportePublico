/// Estatísticas dos intervalos entre atualizações de posição dos ônibus,
/// usadas para verificar o RNF05 (atualização em no máximo 5 segundos).
class IntervalStats {
  const IntervalStats._({
    required this.count,
    required this.meanMs,
    required this.minMs,
    required this.maxMs,
    required this.p95Ms,
    required this.withinLimitPercent,
    required this.limitMs,
  });

  /// Calcula as estatísticas de [intervalsMs] (em milissegundos), com
  /// [limitMs] como limite aceitável (RNF05: 5000 ms).
  factory IntervalStats.of(List<int> intervalsMs, {int limitMs = 5000}) {
    if (intervalsMs.isEmpty) {
      return IntervalStats._(
        count: 0,
        meanMs: 0,
        minMs: 0,
        maxMs: 0,
        p95Ms: 0,
        withinLimitPercent: 0,
        limitMs: limitMs,
      );
    }
    final List<int> sorted = <int>[...intervalsMs]..sort();
    final int count = sorted.length;
    final int sum = sorted.fold<int>(0, (int total, int ms) => total + ms);
    final int within = sorted.where((int ms) => ms <= limitMs).length;
    // Percentil 95 pelo método do posto mais próximo.
    final int p95Index = ((count * 95 + 99) ~/ 100) - 1;
    return IntervalStats._(
      count: count,
      meanMs: sum / count,
      minMs: sorted.first,
      maxMs: sorted.last,
      p95Ms: sorted[p95Index],
      withinLimitPercent: within * 100 / count,
      limitMs: limitMs,
    );
  }

  /// Quantidade de intervalos medidos.
  final int count;

  /// Intervalo médio (ms).
  final double meanMs;

  /// Menor intervalo (ms).
  final int minMs;

  /// Maior intervalo (ms).
  final int maxMs;

  /// 95% dos intervalos ficaram até este valor (ms).
  final int p95Ms;

  /// Porcentagem dos intervalos dentro de [limitMs].
  final double withinLimitPercent;

  /// Limite aceitável (ms).
  final int limitMs;

  /// Todos os intervalos medidos ficaram dentro do limite.
  bool get allWithinLimit => count > 0 && maxMs <= limitMs;
}
