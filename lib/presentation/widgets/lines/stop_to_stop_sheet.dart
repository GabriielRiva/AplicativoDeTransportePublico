import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/speed_profile.dart';
import '../../../domain/entities/stop.dart';
import '../../../domain/usecases/passenger/estimate_between_stops.dart';
import '../map/route_stops.dart';

/// Painel "Tempo entre pontos": o passageiro escolhe a parada de origem e
/// a de destino e vê quanto tempo o ônibus leva entre elas, saindo agora.
class StopToStopSheet extends StatefulWidget {
  /// Cria o painel com as paradas da linha já posicionadas na rota.
  const StopToStopSheet({
    required this.routeStops,
    required this.profile,
    super.key,
  });

  /// Paradas da linha, na ordem, com a distância pela rua até cada uma.
  final RouteStops routeStops;

  /// Velocidades por faixa de horário.
  final SpeedProfile profile;

  /// Abre o painel na parte de baixo da tela.
  static Future<void> show(
    BuildContext context, {
    required RouteStops routeStops,
    required SpeedProfile profile,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) =>
          StopToStopSheet(routeStops: routeStops, profile: profile),
    );
  }

  @override
  State<StopToStopSheet> createState() => _StopToStopSheetState();
}

class _StopToStopSheetState extends State<StopToStopSheet> {
  int _from = 0;
  late int _to = widget.routeStops.stops.length - 1;

  @override
  Widget build(BuildContext context) {
    final List<Stop> stops = widget.routeStops.stops;
    final DateTime now = DateTime.now();
    final StopToStop? estimate = const EstimateBetweenStops()(
      stopMeters: widget.routeStops.stopMeters,
      from: _from,
      to: _to,
      isCircular: widget.routeStops.isCircular,
      totalMeters: widget.routeStops.totalMeters,
      profile: widget.profile,
      departure: now,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text('Tempo entre pontos', style: AppTextStyles.title),
          const SizedBox(height: 4),
          const Text(
            'Escolha onde vai embarcar e onde vai descer.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 16),
          _StopPicker(
            label: 'De',
            icon: Icons.trip_origin,
            stops: stops,
            value: _from,
            onChanged: (int index) => setState(() => _from = index),
          ),
          const SizedBox(height: 12),
          _StopPicker(
            label: 'Até',
            icon: Icons.place_outlined,
            stops: stops,
            value: _to,
            onChanged: (int index) => setState(() => _to = index),
          ),
          const SizedBox(height: 16),
          _Result(
            estimate: estimate,
            fromName: stops[_from].name,
            toName: stops[_to].name,
            sameStop: _from == _to,
            profile: widget.profile,
            now: now,
          ),
        ],
      ),
    );
  }
}

/// Campo de escolha de uma parada da linha.
class _StopPicker extends StatelessWidget {
  const _StopPicker({
    required this.label,
    required this.icon,
    required this.stops,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final List<Stop> stops;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          items: <DropdownMenuItem<int>>[
            for (int i = 0; i < stops.length; i++)
              DropdownMenuItem<int>(
                value: i,
                child: Text(
                  '${stops[i].order}. ${stops[i].name}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (int? index) {
            if (index != null) onChanged(index);
          },
        ),
      ),
    );
  }
}

/// Resultado da estimativa (ou o motivo de não haver uma).
class _Result extends StatelessWidget {
  const _Result({
    required this.estimate,
    required this.fromName,
    required this.toName,
    required this.sameStop,
    required this.profile,
    required this.now,
  });

  final StopToStop? estimate;
  final String fromName;
  final String toName;
  final bool sameStop;
  final SpeedProfile profile;
  final DateTime now;

  String _speedNote() {
    final SpeedBand? band =
        profile.bandAt(now.weekday, SpeedProfile.minuteOfDay(now));
    final double speed = band?.speedKmh ?? profile.defaultSpeedKmh;
    final String label = band == null ? 'horário normal' : band.label;
    return 'Saindo agora: velocidade média de ${speed.round()} km/h '
        '($label) e ${profile.stopDwellSeconds} s parado em cada ponto. '
        'Pode variar com o trânsito.';
  }

  @override
  Widget build(BuildContext context) {
    final StopToStop? value = estimate;
    if (value == null) {
      return Text(
        sameStop
            ? 'Escolha pontos diferentes.'
            : 'Neste sentido o ônibus passa por "$toName" antes de '
                '"$fromName". Escolha um destino depois da origem.',
        style: AppTextStyles.caption,
      );
    }
    final int stops = value.stopsOnTheWay;
    final String stopsText = switch (stops) {
      0 => 'sem paradas',
      1 => '1 parada',
      _ => '$stops paradas',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimaryColor.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryColor.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.schedule, color: kPrimaryColor),
              const SizedBox(width: 8),
              Text(
                '~${value.minutes} min',
                style: AppTextStyles.title.copyWith(fontSize: 22),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${Formatters.distanceMeters(value.meters)} pela rua · '
            '$stopsText no caminho',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 6),
          Text(_speedNote(), style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
