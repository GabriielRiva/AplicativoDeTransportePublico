import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trancity/presentation/widgets/common/app_logo.dart';

void main() {
  testWidgets('AppLogo exibe o nome do aplicativo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppLogo())),
    );

    expect(find.text('TranCity'), findsOneWidget);
  });
}