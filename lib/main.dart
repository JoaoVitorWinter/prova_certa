import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const ProvaCertaApp());
}

class ProvaCertaApp extends StatelessWidget {
  const ProvaCertaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}