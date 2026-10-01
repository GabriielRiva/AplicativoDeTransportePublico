import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Gera marcadores customizados desenhando em canvas, evitando a
/// dependência de assets externos (KISS).
///
/// Os desenhos são feitos em resolução [_renderScale] vezes maior e
/// exibidos no tamanho lógico informado (em dp), para ficarem nítidos em
/// qualquer densidade de tela sem ocupar espaço demais no mapa.
abstract final class MarkerIconUtils {
  static const double _renderScale = 4;

  /// Cria um [BitmapDescriptor] circular com o [icon] centralizado,
  /// exibido com [size] dp de diâmetro.
  static Future<BitmapDescriptor> fromIcon({
    required IconData icon,
    required Color color,
    double size = 40,
    Color iconColor = Colors.white,
  }) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder)..scale(_renderScale);
    final double radius = size / 2;

    canvas.drawCircle(
      Offset(radius, radius),
      radius,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(radius, radius),
      radius - size * 0.05,
      Paint()..color = color,
    );

    final TextPainter painter =
        TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size * 0.55,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: iconColor,
      ),
    );
    painter.layout();
    painter.paint(
      canvas,
      Offset(radius - painter.width / 2, radius - painter.height / 2),
    );

    return _toDescriptor(recorder, size, size);
  }

  /// Ônibus visto de cima, com sombra e sombreamento que dão volume (efeito
  /// 3D quando o mapa está inclinado). A frente aponta para cima, então o
  /// marcador deve ser `flat` e girar com o rumo do ônibus. [width] é a
  /// largura exibida no mapa, em dp; a altura segue a proporção do desenho.
  static Future<BitmapDescriptor> topDownBus({
    Color color = const Color(0xFF2E9E4F),
    double width = 24,
  }) async {
    // Desenho em unidades de uma "prancheta" de 120 x 250.
    const double boardWidth = 120;
    const double boardHeight = 250;
    const Color glass = Color(0xFF2B3A4A);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder)
      ..scale(_renderScale * width / boardWidth);

    RRect box(double l, double t, double r, double b, double radius) =>
        RRect.fromLTRBR(l, t, r, b, Radius.circular(radius));
    Paint solid(Color c) => Paint()..color = c;
    Paint across(Rect rect, List<Color> colors, List<double> stops) =>
        Paint()
          ..shader = ui.Gradient.linear(
            rect.centerLeft,
            rect.centerRight,
            colors,
            stops,
          );

    // Sombra no chão.
    canvas.drawRRect(
      box(16, 18, 112, 246, 26),
      Paint()
        ..color = const Color(0x59000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Retrovisores.
    const Color mirror = Color(0xFF1B2733);
    canvas.drawRRect(box(3, 36, 13, 48, 3), solid(mirror));
    canvas.drawRRect(box(107, 36, 117, 48, 3), solid(mirror));

    // Carroceria: bordas mais escuras e centro mais claro dão o volume.
    final RRect body = box(10, 10, 110, 240, 26);
    final Color edge = _shade(color, -0.13);
    canvas.drawRRect(
      body,
      across(
        body.outerRect,
        <Color>[edge, color, _shade(color, 0.09), color, edge],
        const <double>[0, 0.18, 0.5, 0.82, 1],
      ),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _shade(color, -0.18),
    );

    // Janelas laterais (vistas de cima, como faixas nas bordas).
    canvas.drawRRect(box(13, 66, 19, 214, 3), solid(glass));
    canvas.drawRRect(box(101, 66, 107, 214, 3), solid(glass));

    // Para-brisa com reflexo.
    canvas.drawRRect(
      box(18, 18, 102, 58, 14),
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 18),
          const Offset(0, 58),
          const <Color>[Color(0xFF4F6880), Color(0xFF1F2B37)],
        ),
    );
    canvas.drawPath(
      Path()
        ..moveTo(30, 54)
        ..lineTo(52, 20)
        ..lineTo(64, 20)
        ..lineTo(42, 54)
        ..close(),
      solid(const Color(0x2EFFFFFF)),
    );

    // Teto.
    final RRect roof = box(21, 66, 99, 218, 14);
    final Color roofEdge = _shade(color, 0.20);
    canvas.drawRRect(
      roof,
      across(
        roof.outerRect,
        <Color>[roofEdge, _shade(color, 0.46), roofEdge],
        const <double>[0, 0.5, 1],
      ),
    );

    // Escotilhas.
    final Paint hatch = solid(_shade(color, 0.29));
    canvas.drawRRect(box(48, 80, 72, 98, 4), hatch);
    canvas.drawRRect(box(48, 188, 72, 206, 4), hatch);

    // Ar-condicionado no teto.
    final RRect airConditioner = box(34, 116, 86, 172, 8);
    canvas.drawRRect(
      airConditioner,
      across(
        airConditioner.outerRect,
        const <Color>[Color(0xFFDCE8E0), Colors.white, Color(0xFFDCE8E0)],
        const <double>[0, 0.5, 1],
      ),
    );
    final Paint grille = Paint()
      ..color = const Color(0xFF9FB8A8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(airConditioner, grille);
    grille.strokeWidth = 2;
    for (final double y in <double>[132, 144, 156]) {
      canvas.drawLine(Offset(42, y), Offset(78, y), grille);
    }

    // Vidro traseiro.
    canvas.drawRRect(box(28, 224, 92, 234, 4), solid(glass));

    // Faróis (frente) e lanternas (traseira).
    final Paint headlight = solid(const Color(0xFFFFF4B8));
    canvas.drawCircle(const Offset(24, 15), 4.5, headlight);
    canvas.drawCircle(const Offset(96, 15), 4.5, headlight);
    final Paint taillight = solid(const Color(0xFFE5484D));
    canvas.drawRRect(box(16, 233, 28, 238, 2), taillight);
    canvas.drawRRect(box(92, 233, 104, 238, 2), taillight);

    return _toDescriptor(recorder, width, width * boardHeight / boardWidth);
  }

  static Future<BitmapDescriptor> _toDescriptor(
    ui.PictureRecorder recorder,
    double width,
    double height,
  ) async {
    final ui.Image image = await recorder.endRecording().toImage(
          (width * _renderScale).ceil(),
          (height * _renderScale).ceil(),
        );
    final ByteData? bytes =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: width,
      height: height,
    );
  }

  /// Clareia (delta > 0) ou escurece (delta < 0) uma cor.
  static Color _shade(Color color, double delta) {
    final HSLColor hsl = HSLColor.fromColor(color);
    final double lightness =
        math.max(0.0, math.min(1.0, hsl.lightness + delta));
    return hsl.withLightness(lightness).toColor();
  }
}
