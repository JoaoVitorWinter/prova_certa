import 'package:flutter/material.dart';

import 'turmas_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('AvaliaPro'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TurmasScreen(),
              ),
            );
          },
          child: const Text(
            'Ver turmas',
          ),
        ),
      ),
    );
  }
}