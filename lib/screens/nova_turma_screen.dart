import 'package:flutter/material.dart';

class NovaTurmaScreen extends StatefulWidget {
  const NovaTurmaScreen({super.key});

  @override
  State<NovaTurmaScreen> createState() => _NovaTurmaScreenState();
}

class _NovaTurmaScreenState extends State<NovaTurmaScreen> {
  String nome = '';
  String ano = '';
  String disciplina = '';
  String periodo = 'Manhã';

  bool get formularioPreenchido {
    return nome.isNotEmpty &&
        ano.isNotEmpty &&
        disciplina.isNotEmpty;
  }

  void criarTurma() {
    if (!formularioPreenchido) {
      return;
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        iconTheme: const IconThemeData(
          color: Color(0xFF6545E8),
        ),

        title: const Text(
          'Nova turma',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),

        children: [
          const Text(
            'Informações da turma',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Preencha os dados para criar uma nova turma.',
            style: TextStyle(
              color: Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),

              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Turma',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  decoration: campoDecoration(
                    'Ex: 1º A',
                  ),

                  onChanged: (valor) {
                    setState(() {
                      nome = valor.trim();
                    });
                  },
                ),

                const SizedBox(height: 18),

                const Text(
                  'Ano',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  decoration: campoDecoration(
                    'Ex: 1º Ano',
                  ),

                  onChanged: (valor) {
                    setState(() {
                      ano = valor.trim();
                    });
                  },
                ),

                const SizedBox(height: 18),

                const Text(
                  'Disciplina',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  decoration: campoDecoration(
                    'Ex: Matemática',
                  ),

                  onChanged: (valor) {
                    setState(() {
                      disciplina = valor.trim();
                    });
                  },
                ),

                const SizedBox(height: 18),

                const Text(
                  'Turno',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: periodo,

                  decoration: campoDecoration(null),

                  items: const [
                    DropdownMenuItem(
                      value: 'Manhã',
                      child: Text('Manhã'),
                    ),
                    DropdownMenuItem(
                      value: 'Tarde',
                      child: Text('Tarde'),
                    ),
                    DropdownMenuItem(
                      value: 'Noite',
                      child: Text('Noite'),
                    ),
                  ],

                  onChanged: (valor) {
                    if (valor == null) {
                      return;
                    }

                    setState(() {
                      periodo = valor;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 54,

            child: ElevatedButton(
              onPressed:
                  formularioPreenchido ? criarTurma : null,

              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF6545E8),

                foregroundColor: Colors.white,

                disabledBackgroundColor:
                    const Color(0xFFD8D4F8),

                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),

              child: const Text(
                'Criar turma',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration campoDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
      ),

      filled: true,
      fillColor: const Color(0xFFF8FAFC),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF6545E8),
          width: 1.5,
        ),
      ),
    );
  }
}