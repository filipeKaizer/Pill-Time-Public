import 'package:flutter/material.dart';
import 'package:pill_time/src/providers/memory.dart';
import 'package:pill_time/src/models/remedy.dart';
import 'package:pill_time/src/providers/settings.dart';
import 'package:provider/provider.dart';

class Pillpage extends StatelessWidget {
  const Pillpage({super.key});

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
      itemCount: Provider.of<Memory>(context, listen: false).remedies.length,
      itemBuilder: (context, index) {
        Remedy remedy = Provider.of<Memory>(
          context,
          listen: false,
        ).remedies[index];

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Settings.backgroungListTile,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Image.network(
                    remedy.images.first,
                    fit: BoxFit.cover,
                  ),
                  title: Text(
                    remedy.name,
                    style: TextStyle(color: Colors.black, fontSize: 20),
                  ),
                  subtitle: Text(
                    "${remedy.numPills} pilula${(remedy.numPills > 1) ? "s" : ""}, ${remedy.times.length}x ao dia",
                    style: TextStyle(color: Colors.black),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Tomar às"),
                      Text(
                        (remedy.times.isEmpty)
                            ? "-"
                            : remedy.getNextTime().toString(),
                        style: TextStyle(color: Colors.black, fontSize: 25),
                      ),
                    ],
                  ),
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
