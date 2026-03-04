// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.*
// Test de widget Flutter simple : vérifie que le compteur fonctionne correctement
// Ne modifie pas l'application, juste un test automatisé pour s'assurer que
// le bouton '+' incrémente bien la valeur affichée.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meteo_app/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // On lance l'app pour le test
    await tester.pumpWidget(const MyApp());

    // On vérifie que le compteur commence à 0
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // On appuie sur le bouton '+'
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // On vérifie que le compteur a été incrémenté
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
