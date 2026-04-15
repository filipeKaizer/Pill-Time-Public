import 'package:flutter/material.dart';
import 'package:pill_time/src/models/medicationSchedule.dart';
import 'package:pill_time/src/providers/settings.dart';
import 'package:pill_time/src/tools/cache.dart';
import 'package:pill_time/src/tools/connection.dart';
import 'package:pill_time/src/models/remedy.dart';
import 'package:pill_time/src/tools/notification.dart';
import 'package:pill_time/src/tools/speak.dart';
import 'package:timezone/timezone.dart' as tz;

class Memory with ChangeNotifier {
  bool onWelcomePage = true;
  bool onAssitencePage = false;
  bool onPillPage = false;

  late Connection connection;
  late Notify notification;
  late CacheSystem cache;
  late Speak speak;

  final GlobalKey<NavigatorState> navigatorKey;

  List<Remedy> remedies = [];
  List<MedicationSchedule> schedulesMedications = [];

  Memory({required this.navigatorKey}) {
    connection = Connection();
    notification = Notify(navigatorKey: navigatorKey);
    cache = CacheSystem("cache");
    speak = Speak();
    _init();
  }

  Future<void> _init() async {
    await notification.init();

    schedulesMedications = cache.getAllMedicationSchedules();

    await _initializeRemedies();

    notifyListeners();
  }

  Future<void> _initializeRemedies() async {
    remedies = await connection.getAllRemedies();
  }

  Memory.rand({required this.navigatorKey}) {
    notification = Notify(navigatorKey: navigatorKey);
    connection = Connection();

    notification.init();

    for (int i = 0; i < 10; i++) {
      remedies.add(Remedy.rand(name: "Remédio ${i + 1}"));
    }
  }

  List<DateTime> getListOfDays(int max) {
    return List.generate(
      max,
      (index) => DateTime.now().add(Duration(days: index)),
    );
  }

  List<MedicationSchedule> getMedicationSchedule(int selectedDayOfMounth) {
    return schedulesMedications.where((medicationSchedule) {
      return medicationSchedule.mounthDay == -1 ||
          medicationSchedule.mounthDay == selectedDayOfMounth;
    }).toList();
  }

  List<ListTile> getRemedySugestions() {
    return remedies.map((remedy) {
      return ListTile(
        title: Text(remedy.name),
        trailing: Text(
          remedy.type == PillType.generic ? "Genérico" : "Referência",
        ),
      );
    }).toList();
  }

  void addMedicationSchedule(MedicationSchedule schedule) {
    schedulesMedications.add(schedule);

    registerAllNotifications(Settings.numOfDays);

    notifyListeners();
  }

  void clearMedicationSchedule() {
    schedulesMedications.clear();

    registerAllNotifications(Settings.numOfDays);

    notifyListeners();
  }

  Future<void> registerAllNotifications(int numberOfDays) async {
    cache.saveAllMedicationSchedules(schedulesMedications);

    await notification.cancelAll();

    if (schedulesMedications.isEmpty) return;

    final now = tz.TZDateTime.now(tz.local);

    for (var medicationSchedule in schedulesMedications) {
      for (var time in medicationSchedule.times) {
        for (int i = 0; i <= numberOfDays; i++) {
          final baseDate = now.add(Duration(days: i));

          tz.TZDateTime date;

          if (medicationSchedule.mounthDay != -1) {
            if (baseDate.day != medicationSchedule.mounthDay) continue;

            final lastDayOfMonth = DateTime(
              baseDate.year,
              baseDate.month + 1,
              0,
            ).day;

            final safeDay = medicationSchedule.mounthDay > lastDayOfMonth
                ? lastDayOfMonth
                : medicationSchedule.mounthDay;

            date = tz.TZDateTime(
              tz.local,
              baseDate.year,
              baseDate.month,
              safeDay,
              time.hour,
              time.minute,
            );
          } else {
            date = tz.TZDateTime(
              tz.local,
              baseDate.year,
              baseDate.month,
              baseDate.day,
              time.hour,
              time.minute,
            );
          }

          if (!date.isAfter(now)) continue;

          await notification.addScheduleNotification(
            medicationSchedule.remedy.name,
            "Tomar ${medicationSchedule.qtd} comprimidos de ${medicationSchedule.dose}mg.",
            date,
          );
        }
      }
    }
  }

  void useAssistencePage() {
    onWelcomePage = false;
    onAssitencePage = true;
    onPillPage = false;
    notifyListeners();
  }

  void usePillPage() {
    onWelcomePage = false;
    onAssitencePage = false;
    onPillPage = true;
    notifyListeners();
  }
}
