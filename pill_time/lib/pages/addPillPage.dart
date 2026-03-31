import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pill_time/pages/utils/utils.dart';
import 'package:pill_time/src/models/medicationSchedule.dart';
import 'package:pill_time/src/models/remedy.dart';
import 'package:pill_time/src/providers/memory.dart';
import 'package:pill_time/src/providers/settings.dart';
import 'package:provider/provider.dart';

class Addpillpage extends StatefulWidget {
  const Addpillpage({super.key});

  @override
  State<Addpillpage> createState() => _AddpillpageState();
}

class _AddpillpageState extends State<Addpillpage> {
  MedicationSchedule medicationSchedule = MedicationSchedule();

  void setDosage(double dosage) {
    setState(() => medicationSchedule.dose = dosage);
  }

  void setQtd(int qtd) {
    setState(() => medicationSchedule.qtd = qtd);
  }

  void setHours(List<PillTime> hours) {
    setState(() => medicationSchedule.times = hours);
  }

  void setImages(List<dynamic> images) {
    setState(() {
      medicationSchedule.images = images.map<Image>((img) {
        if (img is File) {
          return Image.file(img);
        } else if (img is String) {
          return Image.network(img);
        } else {
          throw Exception("Tipo de imagem inválido: $img");
        }
      }).toList();
    });
  }

  bool get hasRemedy =>
      medicationSchedule.remedy != null && medicationSchedule.remedy.id != -1;

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
              Provider.of<Memory>(
                context,
                listen: false,
              ).schedulesMedications.add(medicationSchedule);

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
                child: HourSelection(save: setHours),
              ),

            if (hasRemedy)
              SectionCard(
                title: "Imagens",
                child: ImageSelection(save: setImages),
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
          onChanged: (_) => controller.openView(),
          trailing: [
            IconButton(
              onPressed: controller.openView,
              icon: const Icon(Icons.search),
            ),
          ],
        );
      },
      suggestionsBuilder: (context, controller) {
        final remedies = context.read<Memory>().remedies;

        return remedies.map((remedy) {
          return ListTile(
            title: Text(remedy.name),
            trailing: Text(
              remedy.type == PillType.generic ? "Genérico" : "Referência",
            ),
            onTap: () {
              setState(() {
                controller.closeView(remedy.name);
                medicationSchedule.remedy = remedy;
              });
            },
          );
        }).toList();
      },
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
// IMAGENS
//
class ImageSelection extends StatefulWidget {
  Function save;
  ImageSelection({required this.save});

  @override
  State<ImageSelection> createState() => _ImageSelectionState();
}

class _ImageSelectionState extends State<ImageSelection> {
  final List<dynamic> _images = []; // File OU String (URL)
  final ImagePicker _picker = ImagePicker();

  // 🔹 imagens simuladas da rede
  final List<String> networkImages = [
    "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR4d51mCgu-1ofVNrM68Q2cCE7MN-wPdW2XBQ&s",
    "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT_wbUohSUwniG30_TxyKno5Lfmz3m_oDjycw&s",
    "https://raisingchildren.net.au/__data/assets/image/0029/47648/autism-spectrum-disorder-medicationsnarrow.jpg",
  ];

  Future<void> _pickFromGallery() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 70,
    );

    if (picked != null) {
      setState(() => _images.add(File(picked.path)));
    }
  }

  void _showSourceSelector() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        String? selectedUrl;

        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Selecionar origem",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 16),

                    // DISPOSITIVO
                    ListTile(
                      leading: const Icon(Icons.photo),
                      title: const Text("Galeria"),
                      onTap: () {
                        Navigator.pop(context);
                        _pickFromGallery();
                      },
                    ),

                    // REDE
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Selecionar da rede"),

                        DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text("Escolher imagem"),
                          value: selectedUrl,
                          items: networkImages.map((url) {
                            return DropdownMenuItem(
                              value: url,
                              child: Row(
                                children: [
                                  Image.network(url, width: 40, height: 40),
                                  const SizedBox(width: 10),
                                  Text(url.split('/').last),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() => selectedUrl = value);
                          },
                        ),

                        const SizedBox(height: 10),

                        ElevatedButton(
                          onPressed: selectedUrl == null
                              ? null
                              : () {
                                  setState(() => _images.add(selectedUrl));
                                  Navigator.pop(context);
                                },
                          child: const Text("Adicionar"),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    widget.save(_images);
  }

  Widget _buildImage(dynamic image) {
    if (image is File) {
      return Image.file(image, fit: BoxFit.cover);
    } else if (image is String) {
      return Image.network(image, fit: BoxFit.cover);
    }
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _images.length + 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        if (index < _images.length) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImage(_images[index]),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => setState(() => _images.removeAt(index)),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          );
        }

        return GestureDetector(
          onTap: _showSourceSelector,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Settings.secondColor),
            ),
            child: Icon(Icons.add, color: Settings.secondColor),
          ),
        );
      },
    );
  }
}

//
// HORÁRIOS
//
class HourSelection extends StatefulWidget {
  final Function(List<PillTime>) save;

  const HourSelection({required this.save});

  @override
  State<HourSelection> createState() => _HourSelectionState();
}

class _HourSelectionState extends State<HourSelection> {
  String selectedOption = "Intervalo";
  TimeOfDay? selectedTime;

  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: "Intervalo",
                label: Text("Intervalo", style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: "Fixos",
                label: Text("Fixos", style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: "Mensal",
                label: Text("Mensal", style: TextStyle(fontSize: 12)),
              ),
            ],
            selected: {selectedOption},
            onSelectionChanged: (s) => setState(() => selectedOption = s.first),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: pickTime,
          child: Text(
            selectedTime == null
                ? "Selecionar horário"
                : selectedTime!.format(context),
            style: TextStyle(color: Settings.secondColor),
          ),
        ),
      ],
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
