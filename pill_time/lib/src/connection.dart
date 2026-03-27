import 'package:pill_time/src/remedy.dart';
import 'package:pill_time/src/providers/settings.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Connection {
  Future<List<Remedy>> getAllRemedies() async {
    final url = Uri.parse(
      'http://${Settings.api.ip}:${Settings.api.port}/${Settings.api.allRemediesRoute}',
    );
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        List<Remedy> remedies = [];

        data.forEach((id, json) {
          Remedy remedy = Remedy.fromJson(id, json);

          remedies.add(remedy);
        });
        return remedies;
      }

      return [];
    } catch (e) {
      print("Falha ao obter remédios: $e");
      return [];
    }
  }
}
