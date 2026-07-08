import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Exibição padronizada de mensagens ao usuário
/// (CODING_STYLE: snackbars amigáveis).
abstract final class AppSnackbar {
  /// Exibe uma mensagem de erro.
  static void showError(BuildContext context, String message) {
    _show(context, message, kErrorColor);
  }

  /// Exibe uma mensagem de sucesso.
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, kSuccessColor);
  }

  static void _show(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
