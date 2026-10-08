import '../../core/utils/formatters.dart';
import '../../domain/entities/speed_profile.dart';

/// Model de serialização do [SpeedProfile] (nó speedProfile/).
///
/// Exemplo do nó:
/// ```json
/// {
///   "defaultSpeedKmh": 20,
///   "stopDwellSeconds": 20,
///   "bands": {
///     "2_pico_manha": {
///       "label": "Pico da manhã", "start": "07:30", "end": "08:30",
///       "speedKmh": 13, "weekdaysOnly": true
///     }
///   }
/// }
/// ```
/// Valores ausentes ou inválidos usam os de [SpeedProfile.fallback].
class SpeedProfileModel extends SpeedProfile {
  /// Cria o model com os mesmos atributos da entidade.
  const SpeedProfileModel({
    required super.defaultSpeedKmh,
    required super.stopDwellSeconds,
    super.bands,
  });

  /// Constrói o perfil a partir do JSON do nó speedProfile/.
  factory SpeedProfileModel.fromJson(Map<String, dynamic> json) {
    const SpeedProfile fallback = SpeedProfile.fallback;
    final Object? rawBands = json['bands'];
    final Iterable<Object?> entries = rawBands is Map
        ? rawBands.values
        : rawBands is List
            ? rawBands
            : const <Object?>[];
    final List<SpeedBand> bands = <SpeedBand>[];
    for (final Object? entry in entries) {
      if (entry is! Map) continue;
      final SpeedBand? band = _band(Map<String, dynamic>.from(entry));
      if (band != null) bands.add(band);
    }
    final Object? dwell = json['stopDwellSeconds'];
    return SpeedProfileModel(
      defaultSpeedKmh:
          _speed(json['defaultSpeedKmh']) ?? fallback.defaultSpeedKmh,
      stopDwellSeconds: dwell is num && dwell >= 0
          ? dwell.round()
          : fallback.stopDwellSeconds,
      bands: rawBands == null ? fallback.bands : bands,
    );
  }

  static double? _speed(Object? value) {
    if (value is! num || value < 1) return null;
    return value.toDouble();
  }

  static SpeedBand? _band(Map<String, dynamic> json) {
    final Object? start = json['start'];
    final Object? end = json['end'];
    final int? startMinute =
        start is String ? Formatters.parseClock(start) : null;
    final int? endMinute = end is String ? Formatters.parseClock(end) : null;
    final double? speed = _speed(json['speedKmh']);
    if (startMinute == null ||
        endMinute == null ||
        speed == null ||
        endMinute <= startMinute) {
      return null;
    }
    final Object? label = json['label'];
    return SpeedBand(
      label: label is String ? label : '',
      startMinute: startMinute,
      endMinute: endMinute,
      speedKmh: speed,
      weekdaysOnly: json['weekdaysOnly'] == true,
    );
  }
}
