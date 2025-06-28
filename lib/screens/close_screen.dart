import 'package:flutter/material.dart';

class CloseScreen extends StatelessWidget {
  const CloseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Power Map"),
        automaticallyImplyLeading: false, // ❌ Removes back button
      ),
      body: Center(
        child: Text("Map Section", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
