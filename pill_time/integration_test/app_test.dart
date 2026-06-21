// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'package:pill_time/main.dart';
import 'package:pill_time/src/providers/settings.dart';

void main() {
  var settings = Settings();
  patrolTest("Teste de inicio", ($) async {
    await $.pumpWidgetAndSettle(PillTimeWidget(settings: settings));

    // Pagina de boas-vindas
    await $(#WelcomeButton).tap();

    await $.pumpAndSettle();

    expect($(#AssistencePage), findsOneWidget);
  });
}
