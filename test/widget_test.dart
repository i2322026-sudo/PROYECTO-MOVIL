import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movil/main.dart';

void main() {
  testWidgets('La app arranca y muestra la pantalla de login',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verifica que el botón de ingresar esté presente
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
