import 'package:flutter/material.dart';

class Settings with ChangeNotifier {
  static Color backgroundColor = const Color.fromARGB(255, 21, 23, 61);
  static Color secondColor = const Color.fromARGB(255, 152, 37, 152);
  static Color thirtColor = const Color.fromARGB(255, 152, 57, 152);
  static Color bottonBarColor = const Color.fromARGB(255, 30, 33, 86);
  static Color backgroungListTile = const Color.fromARGB(255, 31, 138, 138);

  static API api = API(port: 8325, ip: '200.18.75.25');

  // Número de dias a serem registrados
  static int numOfDays = 7;

  Settings() {
    api = API(port: 8325, ip: '200.18.75.25');
  }
}

class API {
  String ip;
  int port;

  late String imageRoute;
  late String uploadImage;
  late String allRemediesRoute;

  API({required this.port, required this.ip}) {
    imageRoute = 'image';
    allRemediesRoute = 'getRemedies';
    uploadImage = "uploadImage";
  }
}
