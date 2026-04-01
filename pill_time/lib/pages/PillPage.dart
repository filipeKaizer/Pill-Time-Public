import 'package:flutter/material.dart';
import 'package:pill_time/src/models/medicationSchedule.dart';
import 'package:pill_time/src/providers/memory.dart';
import 'package:pill_time/src/providers/settings.dart';
import 'package:provider/provider.dart';

class Pillpage extends StatefulWidget {
  const Pillpage({super.key});

  @override
  State<Pillpage> createState() => _PillpageState();
}

class _PillpageState extends State<Pillpage> {
  @override
  Widget build(BuildContext context) {
    return Provider.of<Memory>(context, listen: false).remedies.isEmpty
        ? EmptyPillList()
        : Padding(padding: const EdgeInsets.only(top: 10), child: PillList());
  }
}

class PillList extends StatelessWidget {
  const PillList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: Provider.of<Memory>(
        context,
        listen: false,
      ).schedulesMedications.length,
      itemBuilder: (context, index) {
        MedicationSchedule remedy = Provider.of<Memory>(
          context,
          listen: true,
        ).schedulesMedications[index];

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: Settings.backgroungListTile, // verde
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
                            ? remedy.images.first
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
