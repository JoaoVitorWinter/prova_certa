import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class ImportarAlunosModal extends StatefulWidget {
  const ImportarAlunosModal({super.key});

  @override
  State<ImportarAlunosModal> createState() =>
      _ImportarAlunosModalState();
}

class _ImportarAlunosModalState extends State<ImportarAlunosModal> {
  String? arquivoSelecionado;

  Future<void> selecionarArquivo() async {
    final arquivo = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
    );

    if (arquivo == null) {
      return;
    }

    setState(() {
      arquivoSelecionado = arquivo.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            const Text(
              'Importar alunos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Selecione uma planilha Excel (.xlsx) ou CSV com as colunas RA e Nome.',
              style: TextStyle(
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: selecionarArquivo,
              icon: const Icon(
                Icons.upload_file_outlined,
              ),
              label: const Text(
                'Selecionar arquivo',
              ),

              style: OutlinedButton.styleFrom(
                foregroundColor:
                    const Color(0xFF6545E8),

                side: const BorderSide(
                  color: Color(0xFF8B7CF6),
                ),

                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),

            if (arquivoSelecionado != null) ...[
              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FA),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      color: Color(0xFF6545E8),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        arquivoSelecionado!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF00A56A),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: arquivoSelecionado == null
                  ? null
                  : () {
                      Navigator.pop(context);
                    },

              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF6545E8),

                foregroundColor: Colors.white,

                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),

              child: const Text(
                'Concluir',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}