import 'package:flutter/material.dart';
import 'package:pill_time/src/models/medicationSchedule.dart';
import 'package:pill_time/src/models/progress.dart';
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
  late Progress progress;

  final GlobalKey<NavigatorState> navigatorKey;

  List<Remedy> remedies = [];
  List<MedicationSchedule> schedulesMedications = [];

  Memory({required this.navigatorKey}) {
    connection = Connection();
    notification = Notify(navigatorKey: navigatorKey);
    cache = CacheSystem("cache");
    speak = Speak();
    progress = Progress();
    _init();
  }

  Future<void> _init() async {
    await notification.init();

    schedulesMedications = cache.getAllMedicationSchedules();

    await _initializeRemedies();

    notifyListeners();
  }

  List<MedicationSchedule> getClosestMedicationSchema(int maxMinutes) {
    List<MedicationSchedule> schedules = [];

    final now = DateTime.now();

    for (MedicationSchedule schedule in schedulesMedications) {
      for (PillTime time in schedule.times) {
        DateTime today = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );

        DateTime yesterday = today.subtract(const Duration(days: 1));
        DateTime tomorrow = today.add(const Duration(days: 1));

        final mapDiffs = {
          -1: yesterday.difference(now).abs(),
          0: today.difference(now).abs(),
          1: tomorrow.difference(now).abs(),
        };

        // Descobre qual offset é o mais próximo
        int closestOffset = mapDiffs.entries
            .reduce((a, b) => a.value < b.value ? a : b)
            .key;

        final minDiff = mapDiffs[closestOffset]!;

        if (minDiff.inMinutes <= maxMinutes) {
          if (!schedules.contains(schedule)) {
            schedules.add(schedule);
          }

          // Cancela APENAS o dia correto
          int id =
              (schedule.id * 1000 +
                      time.hour * 60 +
                      time.minute +
                      closestOffset)
                  .remainder(2000000000);

          notification.cancelById(id);

          break;
        }
      }
    }

    return schedules;
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
    final now = DateTime.now();

    List<MedicationSchedule> filtered = schedulesMedications.where((schedule) {
      return schedule.mounthDay == -1 ||
          schedule.mounthDay == selectedDayOfMounth;
    }).toList();

    filtered.sort((a, b) {
      DateTime getDate(MedicationSchedule s) {
        final t = s.getNextTime();

        DateTime date = DateTime(
          now.year,
          now.month,
          now.day,
          t.hour,
          t.minute,
        );

        // Se já passou, joga pro próximo dia
        if (date.isBefore(now)) {
          date = date.add(const Duration(days: 1));
        }

        return date;
      }

      return getDate(a).compareTo(getDate(b));
    });

    return filtered;
  }

  List<Remedy> getRemedySugestions(String query) {
    return remedies
        .where((r) => r.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void addMedicationSchedule(MedicationSchedule schedule) {
    schedulesMedications.add(schedule);

    registerAllNotifications(Settings.numOfDays);

    notifyListeners();
  }

  void clearMedicationSchedule() {
    schedulesMedications.clear();

    notification.cancelAll();
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
          int id =
              (medicationSchedule.id * 1000 + time.hour * 60 + time.minute + i)
                  .remainder(2000000000);
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
            id,
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
