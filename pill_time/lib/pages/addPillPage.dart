import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pill_time/pages/utils/hourSelectionWidget.dart';
import 'package:pill_time/pages/utils/imageSelectionWidget.dart';
import 'package:pill_time/pages/utils/utils.dart';
import 'package:pill_time/src/models/medicationSchedule.dart';
import 'package:pill_time/src/models/remedy.dart';
import 'package:pill_time/src/providers/memory.dart';
import 'package:pill_time/src/providers/settings.dart';
import 'package:pill_time/src/tools/connection.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

class Addpillpage extends StatefulWidget {
  const Addpillpage({super.key});

  @override
  State<Addpillpage> createState() => _AddpillpageState();
}

String encodeImage(String path) {
  final bytes = File(path).readAsBytesSync();
  return base64Encode(bytes);
}

class _AddpillpageState extends State<Addpillpage> {
  MedicationSchedule medicationSchedule = MedicationSchedule();
  bool get hasRemedy =>
      medicationSchedule.remedy != null && medicationSchedule.remedy.id != -1;

  List<Image> remedyImages = [];
  String medicationsSugestion = "";

  void setDosage(double dosage) {
    setState(() => medicationSchedule.dose = dosage);
  }

  void setQtd(int qtd) {
    setState(() => medicationSchedule.qtd = qtd);
  }

  void setHours(List<PillTime> hours) {
    setState(() => medicationSchedule.times = hours);
  }

  void setImages(List<dynamic> images) async {
    final futures = images.map((img) async {
      if (img is File) {
        return await compute(encodeImage, img.path);
      } else if (img is String) {
        return img;
      }
      return null;
    });

    final results = await Future.wait(futures);

    if (!mounted) return;

    setState(() {
      medicationSchedule.images = results.whereType<String>().toList();
    });
  }

  String _encode(String path) {
    final bytes = File(path).readAsBytesSync();
    return base64Encode(bytes);
  }

  void setMounthDay(int dayOfMounth) {
    setState(() {
      medicationSchedule.mounthDay = dayOfMounth;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Adicionar remédio",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Settings.secondColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (medicationSchedule.remedy.isNone()) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return _buildAlert(
                      "Remédio não informado",
                      "Antes de salvar, selecione um remédio.",
                    );
                  },
                );
                return;
              }
              if (medicationSchedule.times.isEmpty) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return _buildAlert(
                      "Horário ausente",
                      "Antes de salvar, informe ao menos um horário.",
                    );
                  },
                );
                return;
              }

              final memory = context.read<Memory>();
              if (medicationSchedule.qtd == 0) medicationSchedule.qtd = 1;
              memory.addMedicationSchedule(medicationSchedule);

              Navigator.pop(context);
            },
            child: const Text("Salvar", style: TextStyle(color: Colors.white)),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            SectionCard(title: "Remédio", child: _buildSearch()),

            if (hasRemedy)
              SectionCard(
                title: "Dose",
                child: DosageSelection(
                  setDosage: setDosage,
                  medicationSchedule: medicationSchedule,
                ),
              ),

            if (hasRemedy)
              SectionCard(
                title: "Quantidade",
                child: QtdSelector(
                  changeQtd: setQtd,
                  title: "Quantidade",
                  description: "Quantidade por uso",
                ),
              ),

            if (hasRemedy)
              SectionCard(
                title: "Horários",
                child: HourSelection(
                  save: setHours,
                  setMounthDay: setMounthDay,
                ),
              ),

            if (hasRemedy)
              SectionCard(
                title: "Imagens",
                child: ImageSelection(
                  save: setImages,
                  remedy: medicationSchedule.remedy,
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return SearchAnchor(
      builder: (context, controller) {
        return SearchBar(
          hintText: "Buscar remédio...",
          controller: controller,
          onTap: controller.openView,
          onChanged: (value) {
            setState(() {
              medicationsSugestion = value;
            });
            controller.openView();
          },
          trailing: [
            IconButton(
              onPressed: controller.openView,
              icon: const Icon(Icons.search),
            ),
          ],
        );
      },
      suggestionsBuilder: (context, controller) {
        final memory = context.read<Memory>();

        final query = controller.text.trim();

        final suggestions = memory.getRemedySugestions(query);
        print(suggestions);

        return suggestions.map((remedy) {
          return ListTile(
            title: Text(remedy.name),
            trailing: Text(
              remedy.type == PillType.generic ? "Genérico" : "Referência",
            ),
            onTap: () async {
              controller.closeView(remedy.name);

              Future.delayed(const Duration(milliseconds: 100), () {
                FocusManager.instance.primaryFocus?.unfocus();
              });

              final images = await Connection.getImagesByRemedy(remedy.id);

              if (!mounted) return;

              setState(() {
                medicationSchedule.remedy = remedy;
                medicationSchedule.remedy.images = images;
              });
            },
          );
        }).toList();
      },
    );
  }

  Widget _buildAlert(String title, String content) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text("Ok"),
        ),
      ],
    );
  }
}

//
// CARD
//
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 20,
      margin: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Settings.secondColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Settings.secondColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

//
// DOSE
//
class DosageSelection extends StatefulWidget {
  final Function(double) setDosage;
  final MedicationSchedule medicationSchedule;

  const DosageSelection({
    super.key,
    required this.setDosage,
    required this.medicationSchedule,
  });

  @override
  State<DosageSelection> createState() => _DosageSelectionState();
}

class _DosageSelectionState extends State<DosageSelection> {
  @override
  Widget build(BuildContext context) {
    final dosages = widget.medicationSchedule.remedy.dosages;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dosages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final dose = dosages[index];
        final isSelected = widget.medicationSchedule.dose == dose;

        return GestureDetector(
          onTap: () {
            widget.setDosage(dose);
            setState(() {});
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? Settings.secondColor : Colors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "${dose.toStringAsFixed(0)} mg",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}
