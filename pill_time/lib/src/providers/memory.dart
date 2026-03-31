import 'package:flutter/material.dart';
import 'package:pill_time/src/models/medicationSchedule.dart';
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

    notification.scheduleNotification(
      "Sertralina",
      "Tomar 1 pilula",
      TZDateTime.now(tz.local).add(Duration(seconds: 10)),
    );
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

    notification.scheduleNotification(
      "Sertralina",
      "Tomar 1 pilula",
      TZDateTime.now(tz.local).add(Duration(seconds: 10)),
    );
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

  // Future<File?> pickImage() async {
  //   ImagePicker imagePicker = ImagePicker();
  //   final picked = await imagePicker.pickImage(source: ImageSource.gallery);

  //   if (picked != null) {
  //     return File(picked.path);
  //   }

  //   return null;
  // }

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
