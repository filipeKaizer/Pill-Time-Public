import 'package:flutter/material.dart';
import 'package:pill_time/src/providers/memory.dart';
import 'package:pill_time/src/providers/settings.dart';
import 'package:provider/provider.dart';

class Assistencepage extends StatelessWidget {
  const Assistencepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Settings.backgroundColor,
      body: Center(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 12,
              right: 12,
              top: 20,
              bottom: 20,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Assistências",
                  style: TextStyle(
                    color: Color.fromARGB(255, 200, 107, 209),
                    fontSize: 30,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height / 15),
                // Lista de assistencias
                AssistenceList(),

                // Próximo
                ElevatedButton(
                  onPressed: () {
                    Provider.of<Memory>(context, listen: false).usePillPage();
                  },
                  child: Text(
                    'Prosseguir',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  style: ButtonStyle(
                    minimumSize: WidgetStateProperty.all(
                      Size(double.infinity, 50),
                    ),
                    backgroundColor: WidgetStateProperty.all(
                      Color.fromARGB(255, 152, 37, 152),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AssistenceList extends StatefulWidget {
  const AssistenceList({super.key});

  @override
  State<AssistenceList> createState() => _AssistenceListState();
}

class _AssistenceListState extends State<AssistenceList> {
  bool readAssist = false;
  bool imageAssist = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            child: AssistenceListItem(
              title: "Leitura",
              icon: Icons.record_voice_over_rounded,
              selected: readAssist,
            ),
            onTap: () {
              setState(() {
                readAssist = !readAssist;
              });
            },
          ),
          SizedBox(height: 10),
          InkWell(
            child: AssistenceListItem(
              title: "Imagem",
              icon: Icons.image,
              selected: imageAssist,
            ),
            onTap: () {
              setState(() {
                imageAssist = !imageAssist;
              });
            },
          ),
        ],
      ),
    );
  }
}

class AssistenceListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  const AssistenceListItem({
    required this.title,
    required this.icon,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height / 8,
      decoration: BoxDecoration(
        color: selected ? Settings.secondColor : Colors.white70,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 2, bottom: 2),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: selected ? Colors.white70 : Colors.black87,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    color: selected ? Colors.white70 : Colors.black87,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
