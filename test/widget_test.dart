// This is a basic Flutter widget test for the CambioPreciosDIGEMID app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appnew_0/main.dart';

void main() {
  testWidgets('App initializes and shows Login screen on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
