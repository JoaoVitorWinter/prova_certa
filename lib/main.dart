import 'package:flutter/material.dart';

void main() {
  runApp(const AvaliaProApp());
}

class AvaliaProApp extends StatelessWidget {
  const AvaliaProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AvaliaPro',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('AvaliaPro'),
        ),
        body: const Center(
          child: Text('AvaliaPro'),
        ),
      ),
    );
  }
}