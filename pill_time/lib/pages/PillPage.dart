import 'package:flutter/material.dart';
import 'package:pill_time/src/models/medicationSchedule.dart';
import 'package:pill_time/src/providers/memory.dart';
import 'package:pill_time/src/providers/settings.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

class Pillpage extends StatefulWidget {
  const Pillpage({super.key});

  @override
  State<Pillpage> createState() => _PillpageState();
}

class _PillpageState extends State<Pillpage> {
  @override
  Widget build(BuildContext context) {
    return context.watch<Memory>().remedies.isEmpty
        ? EmptyPillList()
        : Padding(padding: const EdgeInsets.only(top: 10), child: PillList());
  }
}

class PillList extends StatefulWidget {
  const PillList({super.key});

  @override
  State<PillList> createState() => _PillListState();
}

class _PillListState extends State<PillList> {
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    Memory memory = context.watch<Memory>();
    List<DateTime> listOfDays = memory.getListOfDays(7);

    List<MedicationSchedule> listMedicationSchedule = memory
        .getMedicationSchedule(listOfDays[selectedIndex].day);

    String _getWeekday(int weekday) {
      const days = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];
      return days[weekday - 1];
    }

    return Column(
      children: [
        // Seletor de dias
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: listOfDays.length,
            itemBuilder: (context, index) {
              final day = listOfDays[index];
              final isSelected = index == selectedIndex;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  width: 70,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Settings.secondColor
                        : Settings.backgroungListTile,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Settings.secondColor
                          : Colors.white.withOpacity(0.2),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Settings.secondColor.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Dia da semana
                      Text(
                        _getWeekday(day.weekday),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Número do dia
                      Text(
                        day.day.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : Settings.secondColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        SizedBox(height: 20),

        // Lista
        Expanded(
          child: ListView.builder(
            itemCount: listMedicationSchedule.length,
            itemBuilder: (context, index) {
              MedicationSchedule remedy = listMedicationSchedule[index];

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Container(
                    height: 110,
                    decoration: BoxDecoration(
                      color: Settings.backgroungListTile,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          // Imagem
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: remedy.images.isNotEmpty
                                  ? Image.memory(
                                      base64Decode(remedy.images.first),
                                      fit: BoxFit.cover,
                                      width: 60,
                                      height: 60,
                                    )
                                  : Container(
                                      color: Colors.white.withOpacity(0.2),
                                      child: const Icon(
                                        Icons.medication,
                                        size: 30,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Informações
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                /// Nome
                                Text(
                                  remedy.remedy.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 4),

                                // Quantidade
                                Text(
                                  "${remedy.qtd} pílula${(remedy.qtd > 1) ? "s" : ""} • ${remedy.times.length}x ao dia",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 13,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                // Dia do mês
                                if (remedy.mounthDay != -1)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "Somente no dia ${remedy.mounthDay}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Horário
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Próximo às",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                (remedy.times.isEmpty)
                                    ? "--:--"
                                    : remedy.getNextTime().toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class EmptyPillList extends StatelessWidget {
  const EmptyPillList({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Você ainda não possui remédios registrados...",
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}
