import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Gera os marcadores customizados dos mapas: ícones desenhados em canvas
/// e imagens PNG dos assets.
///
/// Os ícones desenhados são feitos em resolução [_renderScale] vezes maior
/// e exibidos no tamanho lógico informado (em dp), para ficarem nítidos em
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

  /// Carrega uma imagem PNG dos assets do app como marcador, exibida com
  /// [width] dp de largura (a altura segue a proporção da imagem).
  static Future<BitmapDescriptor> fromAsset(
    String assetPath, {
    required double width,
  }) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.ImmutableBuffer buffer =
        await ui.ImmutableBuffer.fromUint8List(bytes);
    final ui.ImageDescriptor descriptor =
        await ui.ImageDescriptor.encoded(buffer);
    final double height = width * descriptor.height / descriptor.width;
    descriptor.dispose();
    buffer.dispose();
    return BitmapDescriptor.bytes(bytes, width: width, height: height);
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
}
