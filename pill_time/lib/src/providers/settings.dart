import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

class Settings with ChangeNotifier {
  late Box box;

  static Color backgroundColor = const Color.fromARGB(255, 21, 23, 61);
  static Color secondColor = const Color.fromARGB(255, 152, 37, 152);
  static Color thirtColor = const Color.fromARGB(255, 152, 57, 152);
  static Color bottonBarColor = const Color.fromARGB(255, 30, 33, 86);
  static Color backgroungListTile = const Color.fromARGB(255, 31, 138, 138);

  API api = API(port: 8326, ip: '200.18.75.25');

  // Número de dias a serem registrados
  int numOfDays = 7;
  // Numero de minutos de proximidade entre remédios
  int closestTime = 15;

  // Regras de pontuação
  int perRemedy = 1;
  int perSequentialDay = 3;

  // Tamanho do texto
  double textSize = 1;

  // Assistencias
  bool voiceAssist = true;
  bool textAssist = false;

  // Introdução
  bool firstUse = true;

  Settings() {
    box = Hive.box('settings');

    final data = box.get('settings');

    if (data == null) {
      print("Data é null");
      numOfDays = 7;
      closestTime = 15;
      perRemedy = 1;
      perSequentialDay = 3;
      textSize = 1;
    } else {
      try {
        Map<String, dynamic> json = castMap(data);

        numOfDays = json['numDays'] ?? 7;
        closestTime = json['closestTime'] ?? 15;
        textSize = json['textSize'] ?? 15.0;
        api = API(port: json['port'] ?? 8326, ip: json['ip'] ?? '200.18.75.25');
        voiceAssist = json['voice'];
        textAssist = json['text'];
        firstUse = json['firstUse'];
      } catch (e) {
        print("Erro no carregamento de configurações: $e");
      }
    }
  }

  void saveCache() {
    try {
      box.put('settings', toJson());
    } catch (e) {
      print("Erro ao salvar configurações: $e");
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'numDays': numOfDays,
      'closestTime': closestTime,
      'textSize': textSize,
      'ip': api.ip,
      'port': api.port,
      'voice': voiceAssist,
      'text': textAssist,
      'firstUse': firstUse,
    };
  }

  Map<String, dynamic> castMap(Map<dynamic, dynamic> map) {
    return map.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), castMap(value));
      } else if (value is List) {
        return MapEntry(
          key.toString(),
          value.map((e) {
            if (e is Map) {
              return castMap(e);
            }
            return e;
          }).toList(),
        );
      }
      return MapEntry(key.toString(), value);
    });
  }

  void setNewValues({
    required int numOfDays,
    required int closestTime,
    required double textSize,
    required int port,
    required String ip,
  }) {
    this.numOfDays = numOfDays;
    this.closestTime = closestTime;
    this.textSize = textSize;
    this.api.ip = ip;
    this.api.port = port;
  }
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
