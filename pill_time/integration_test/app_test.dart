import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:patrol/patrol.dart';
import 'package:pill_time/main.dart';
import 'package:pill_time/src/providers/memory.dart';
import 'package:pill_time/src/providers/settings.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class _AppHarness {
  _AppHarness({required this.settings, required this.memory});

  final Settings settings;
  final Memory memory;
}

Future<void> _resetBoxes() async {
  await Hive.box('cache').clear();
  await Hive.box('settings').clear();
}

Future<_AppHarness> _pumpTestApp(PatrolIntegrationTester $) async {
  await _resetBoxes();

  final settings = Settings()
    ..firstUse = true
    ..voiceAssist = true
    ..textAssist = false
    ..textSize = 1;
  settings.saveCache();

  final memory = Memory(navigatorKey: navigatorKey, settings: settings);

  await $.pumpWidgetAndSettle(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<Settings>.value(value: settings),
        ChangeNotifierProvider<Memory>.value(value: memory),
      ],
      child: PillTimeWidget(settings: settings),
    ),
  );

  return _AppHarness(settings: settings, memory: memory);
}

Future<void> _tapAndSettle(
  PatrolIntegrationTester $,
  Finder finder, {
  bool ensureVisible = true,
}) async {
  if (ensureVisible) {
    await $.tester.ensureVisible(finder);
  }
  await $.tester.tap(finder);
  await $.pumpAndSettle();
}

Future<void> _enterText(
  PatrolIntegrationTester $,
  Finder finder,
  String text,
) async {
  await $.tester.ensureVisible(finder);
  await $.tester.enterText(finder, text);
  await $.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    final hivePath = Directory.systemTemp
        .createTempSync('pill_time_patrol_test_')
        .path;

    Hive.init(hivePath);
    await Hive.openBox('cache');
    await Hive.openBox('settings');
  });

  patrolTest('fluxo completo do PillTime', ($) async {
    final harness = await _pumpTestApp($);

    expect(find.byKey(const Key('WelcomeButton')), findsOneWidget);
    await _tapAndSettle($, find.byKey(const Key('WelcomeButton')));
    expect(find.byKey(const Key('AssistencePage')), findsOneWidget);

    await _tapAndSettle($, find.byKey(const Key('VoiceAssistanceInfoButton')));
    expect(find.text('Entendi'), findsOneWidget);
    await _tapAndSettle($, find.text('Entendi'));

    await _tapAndSettle($, find.byKey(const Key('VisualAssistanceItem')));
    expect(harness.settings.textAssist, isTrue);

    await _tapAndSettle($, find.byKey(const Key('AssistanceProceedButton')));
    expect(find.byKey(const Key('PillPage')), findsOneWidget);

    await _tapAndSettle($, find.byKey(const Key('ProgressTab')));
    expect(find.byKey(const Key('ProgressPage')), findsOneWidget);

    await _tapAndSettle($, find.byKey(const Key('SettingsTab')));
    expect(find.byKey(const Key('SettingsPage')), findsOneWidget);
    expect(find.byKey(const Key('ServerIpField')), findsOneWidget);
    expect(find.byKey(const Key('ServerPortField')), findsOneWidget);

    await _tapAndSettle($, find.byKey(const Key('PillsTab')));
    expect(find.byKey(const Key('PillPage')), findsOneWidget);

    await _tapAndSettle($, find.byKey(const Key('AddPillFab')));
    expect(find.byKey(const Key('AddPillPage')), findsOneWidget);

    await _tapAndSettle($, find.byKey(const Key('AddPillSaveButton')));
    expect(find.text('RemÃ©dio nÃ£o informado'), findsOneWidget);
    await _tapAndSettle($, find.text('Ok'));

    await _tapAndSettle($, find.byKey(const Key('AddManualRemedyButton')));
    await _enterText(
      $,
      find.byKey(const Key('ManualRemedyNameField')),
      'Patrolina',
    );
    await _enterText($, find.byKey(const Key('ManualRemedyDoseField')), '100');
    await _tapAndSettle($, find.byKey(const Key('ManualRemedyConfirmButton')));

    await _tapAndSettle($, find.byKey(const Key('DosageOption_100')));
    await _tapAndSettle(
      $,
      find.byKey(const Key('MedicationQuantityIncrementButton')),
    );
    expect(find.byKey(const Key('MedicationQuantityValue')), findsOneWidget);

    await _tapAndSettle($, find.byKey(const Key('ManualScheduleTab')));
    await _tapAndSettle($, find.byKey(const Key('ManualTimePickerButton')));
    await _tapAndSettle($, find.text('OK'), ensureVisible: false);
    await _tapAndSettle($, find.byKey(const Key('ManualAddTimeButton')));

    await _tapAndSettle($, find.byKey(const Key('AddPillSaveButton')));
    expect(find.byKey(const Key('PillPage')), findsOneWidget);
    expect(find.text('Patrolina'), findsOneWidget);
    expect(harness.memory.schedulesMedications, hasLength(1));

    await _tapAndSettle($, find.byKey(const Key('SettingsTab')));
    await _tapAndSettle($, find.byKey(const Key('ClearSchedulesButton')));
    await _tapAndSettle($, find.text('Apagar'));
    expect(harness.memory.schedulesMedications, isEmpty);
  });
}
