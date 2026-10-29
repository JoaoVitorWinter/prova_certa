import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/prova.dart';

/// Mostra novamente o QR Code da mesma prova já guardada no Firebase.
/// O ID não é recriado: usa-se sempre prova.id.
class QrProvaScreen extends StatelessWidget {
  final Prova prova;

  const QrProvaScreen({super.key, required this.prova});

  @override
  Widget build(BuildContext context) {
    final gabarito = (prova.gabaritoOficial ?? <String>[])
    .map((resposta) => resposta.toUpperCase().trim())
    .toList();

    final qrCodeData = jsonEncode({
      'app': 'prova_certa',
      'tipo': 'gabarito_prova',
      'versao': 1,
      'provaId': prova.id,
      'turmaId': prova.turma.id,
      'gabarito': gabarito,
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('QR Code da prova'),
        backgroundColor: const Color(0xFFF5F7FB),
        foregroundColor: const Color(0xFF101827),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9E7FF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    color: Color(0xFF5146EE),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  prova.nome,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF101827),
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Turma: ${prova.turma.nome}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF667A96)),
                ),
                const SizedBox(height: 20),
                if (gabarito.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Esta prova não tem um gabarito oficial guardado. '
                      'Não é possível gerar o QR Code de correção com segurança.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF8A4B08)),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D1B2740),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: qrCodeData,
                          version: QrVersions.auto,
                          size: 250,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'QR CODE OFICIAL',
                          style: TextStyle(
                            color: Color(0xFF101827),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${gabarito.length} questões • ID: ${prova.id}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF667A96),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                const Text(
                  'Mantém este código reservado ao professor: o conteúdo inclui '
                  'o gabarito oficial da prova.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF667A96),
                    fontSize: 12,
                    height: 1.5,
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
