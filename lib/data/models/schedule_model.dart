import '../../domain/entities/schedule.dart';

/// Model de serialização do [Schedule] (nó schedules/ do Realtime
/// Database).
class ScheduleModel extends Schedule {
  /// Cria o model com os mesmos atributos da entidade.
  const ScheduleModel({
    required super.id,
    required super.lineId,
    required super.departureTime,
    required super.weekday,
  });

  /// Constrói o horário a partir do JSON do nó schedules/{scheduleId}.
  ///
  /// Aceita tanto a chave departureTime (API_SPEC) quanto
  /// departure (FIREBASE_SCHEMA).
  factory ScheduleModel.fromJson(String id, Map<String, dynamic> json) {
    return ScheduleModel(
      id: id,
      lineId: json['lineId'] as String? ?? '',
      departureTime:
          (json['departureTime'] ?? json['departure'])?.toString() ?? '',
      weekday: (json['weekday'] as num?)?.toInt() ?? DateTime.monday,
    );
  }

  /// Converte o horário para o JSON persistido em schedules/{scheduleId}.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'lineId': lineId,
      'departureTime': departureTime,
      'weekday': weekday,
    };
  }
}
