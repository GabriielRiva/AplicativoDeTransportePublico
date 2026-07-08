import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Logotipo textual do TranCity.
class AppLogo extends StatelessWidget {
  /// Cria o logo com o [fontSize] desejado.
  const AppLogo({super.key, this.fontSize = 36});

  /// Tamanho da fonte do logo.
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      kAppName,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: kPrimaryColor,
        shadows: const <Shadow>[
          Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black26),
        ],
      ),
    );
  }
}
