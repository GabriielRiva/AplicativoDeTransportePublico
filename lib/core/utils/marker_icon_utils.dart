import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Gera marcadores customizados desenhando ícones Material em canvas,
/// evitando a dependência de assets externos (KISS).
abstract final class MarkerIconUtils {
  /// Cria um [BitmapDescriptor] circular com o [icon] centralizado.
  static Future<BitmapDescriptor> fromIcon({
    required IconData icon,
    required Color color,
    double size = 96,
    Color iconColor = Colors.white,
  }) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final double radius = size / 2;

    canvas.drawCircle(
      Offset(radius, radius),
      radius,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(radius, radius),
      radius - 5,
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

    final ui.Image image = await recorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final ByteData? bytes =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }
}