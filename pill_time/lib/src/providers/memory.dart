import 'package:flutter/material.dart';
import 'package:pill_time/src/models/medicationSchedule.dart';
import 'package:pill_time/src/providers/settings.dart';
import 'package:pill_time/src/tools/connection.dart';
import 'package:pill_time/src/models/remedy.dart';
import 'package:pill_time/src/tools/notification.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone/timezone.dart' as tz;

class Memory with ChangeNotifier {
  bool onWelcomePage = true;
  bool onAssitencePage = false;
  bool onPillPage = false;

  late Connection connection;
  late Notify notification;

  final GlobalKey<NavigatorState> navigatorKey;

  List<Remedy> remedies = [];
  List<MedicationSchedule> schedulesMedications = [];

  Memory({required this.navigatorKey}) {
    connection = Connection();
    notification = Notify(navigatorKey: navigatorKey);
    _initializeRemedies();

    notification.init();
  }

  Future<void> _initializeRemedies() async {
    remedies = await connection.getAllRemedies();
    notifyListeners();
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
    List<DateTime> days = [];

    for (int d = 0; d < max; d++) {
      days.add(DateTime.now().add(Duration(days: d)));
    }

    return days;
  }

  List<MedicationSchedule> getMedicationSchedule(int selectedDayOfMounth) {
    List<MedicationSchedule> list = [];

    for (MedicationSchedule medicationSchedule in schedulesMedications) {
      if (medicationSchedule.mounthDay == -1 ||
          medicationSchedule.mounthDay == selectedDayOfMounth) {
        list.add(medicationSchedule);
      }
    }

    return list;
  }

  List<ListTile> getRemedySugestions() {
    if (remedies.isNotEmpty) {
      return remedies.map((remedy) {
        return ListTile(
          title: Text(remedy.name),
          trailing: Text(
            "${(remedy.type == PillType.generic) ? "Genérico" : "Referência"}",
          ),
        );
      }).toList();
    }

    return [];
  }

  void addMedicationSchedule(MedicationSchedule schedule) {
    schedulesMedications.add(schedule);
    for (PillTime time in schedule.times) {
      print(time.hour);
    }
    print(schedule.dose);
    print(schedule.qtd);

    // Registra as notificações
    registerAllNotifications(Settings.numOfDays);

    notifyListeners();
  }

  Future<void> registerAllNotifications(int numberOfDays) async {
    await notification.cancelAll();

    if (schedulesMedications.isEmpty) return;

    final now = tz.TZDateTime.now(tz.local);

    for (MedicationSchedule medicationSchedule in schedulesMedications) {
      for (PillTime time in medicationSchedule.times) {
        // percorre hoje + próximos dias
        for (int i = 0; i <= numberOfDays; i++) {
          final baseDate = now.add(Duration(days: i));

          tz.TZDateTime date;

          // CASO tenha dia fixo no mês
          if (medicationSchedule.mounthDay != -1) {
            // só agenda se o dia bater
            if (baseDate.day != medicationSchedule.mounthDay) continue;

            // garante dia válido no mês
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
              0,
            );
          } else {
            // caso normal (todo dia)
            date = tz.TZDateTime(
              tz.local,
              baseDate.year,
              baseDate.month,
              baseDate.day,
              time.hour,
              time.minute,
              0,
            );
          }

          // evita passado
          if (!date.isAfter(now)) continue;

          await notification.addScheduleNotification(
            medicationSchedule.remedy.name,
            "Tomar ${medicationSchedule.qtd} doses/comprimidos de ${medicationSchedule.dose}mg.",
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
