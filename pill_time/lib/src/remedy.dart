import 'dart:math';

import 'package:flutter/material.dart';

class Remedy {
  late String name;
  late double dosage = 0.0;
  late int numPills = 0;
  late PillType type;
  late int id = 0;

  late List<PillTime> times = [];
  late List<String> images = [];
  late List<double> dosages = [];

  @override
  String toString() {
    return "$name, ${dosages[0]} ($type)";
  }

  Remedy.rand({required this.name}) {
    var random = Random();

    times.clear();
    for (int i = 0; i < random.nextInt(4); i++) {
      print("Gerando tempo $i");
      this.times.add(PillTime.rand());
    }

    this.numPills = random.nextInt(3);
    this.type = PillType.generic;
    this.dosage = random.nextDouble() * 50;

    images.add(
      "https://www.drogariaminasbrasil.com.br/media/webp/catalog/product/cache/c5b0e6136a6dd7f7d91d8b889ed40f35/image/58877352b/assert-25mg-com-30-comprimidos_jpg.webp",
    );
  }

  Remedy.fromJson(String ids, Map<String, dynamic> json) {
    id = int.parse(ids);

    name = json['name'];
    type = (json['type'] == 'generico') ? PillType.generic : PillType.original;
    dosages = (json['dose'] as List).map((e) => double.parse(e)).toList();

    // Provisório
    images.add(
      "https://www.drogariaminasbrasil.com.br/media/webp/catalog/product/cache/c5b0e6136a6dd7f7d91d8b889ed40f35/image/58877352b/assert-25mg-com-30-comprimidos_jpg.webp",
    );
  }

  PillTime getNextTime() {
    if (times.isEmpty) {
      return PillTime(hour: 0, minute: 0);
    }

    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;

    PillTime? nextTime;
    int minDifference = 1440;

    for (final time in times) {
      final timeInMinutes = time.hour * 60 + time.minute;
      int difference = timeInMinutes - currentTimeInMinutes;

      if (difference < 0) {
        difference += 1440;
      }

      if (difference < minDifference) {
        minDifference = difference;
        nextTime = time;
      }
    }

    return nextTime ?? times.first;
  }
}

class PillTime {
  late int hour = 0;
  late int minute = 0;

  PillTime({required this.hour, required this.minute});

  PillTime.rand() {
    var random = Random();

    this.hour = random.nextInt(24);
    this.minute = random.nextInt(59);

    print("$hour:$minute");
  }

  String toString() {
    return "${hour < 10 ? "0" : ""}$hour:${minute < 10 ? "0" : ""}$minute";
  }
}

enum PillType { generic, original }
