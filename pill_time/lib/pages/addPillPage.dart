import 'package:flutter/material.dart';

class Addpillpage extends StatefulWidget {
  const Addpillpage({super.key});

  @override
  State<Addpillpage> createState() => _AddpillpageState();
}

class _AddpillpageState extends State<Addpillpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {},
          icon: Icon(Icons.arrow_back, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          "Adicionar remédio",
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
      ),
    );
  }
}
