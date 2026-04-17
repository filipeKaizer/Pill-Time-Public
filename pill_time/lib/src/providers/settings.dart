import 'package:flutter/material.dart';

class Settings with ChangeNotifier {
  static Color backgroundColor = const Color.fromARGB(255, 21, 23, 61);
  static Color secondColor = const Color.fromARGB(255, 152, 37, 152);
  static Color thirtColor = const Color.fromARGB(255, 152, 57, 152);
  static Color bottonBarColor = const Color.fromARGB(255, 30, 33, 86);
  static Color backgroungListTile = const Color.fromARGB(255, 31, 138, 138);

  static API api = API(port: 8326, ip: '200.18.75.25');

  // Número de dias a serem registrados
  static int numOfDays = 7;
  // Numero de minutos de proximidade entre remédios
  static int closestTime = 20;

  // Regras de pontuação
  static int perRemedy = 1;
  static int perSequentialDay = 5;

  Settings();
}

class API {
  String ip;
  int port;

  late String uploadImageRoute;
  late String allRemediesRoute;
  late String getImageRoute;

  API({required this.port, required this.ip}) {
    allRemediesRoute = 'getRemedies';
    uploadImageRoute = "uploadImage";
    getImageRoute = "image";
  }
}
