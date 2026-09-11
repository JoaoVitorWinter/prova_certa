import 'package:flutter/material.dart';

import '../models/questao.dart';
import 'banco_questoes_screen.dart';
import 'selecionar_questoes_screen.dart';
import 'turmas_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> abrirSelecaoQuestoes(BuildContext context) async {
    final escolhidas = await Navigator.push<List<Questao>>(
      context,
      MaterialPageRoute(
        builder: (context) => const SelecionarQuestoesScreen(),
      ),
    );

    if (escolhidas == null || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${escolhidas.length} questões selecionadas para a prova.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'AvaliaPro',

          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(14),

        children: [
          const Text(
            'O que você quer fazer?',

            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Gerencie suas turmas e o banco de questões.',

            style: TextStyle(
              color: Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 20),

          MenuCard(
            icone: Icons.groups_outlined,
            titulo: 'Turmas',
            descricao: 'Veja as turmas e os alunos cadastrados',

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TurmasScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          MenuCard(
            icone: Icons.quiz_outlined,
            titulo: 'Banco de Questões',
            descricao: 'Crie, edite e organize suas questões',

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BancoQuestoesScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          MenuCard(
            icone: Icons.fact_check_outlined,
            titulo: 'Selecionar questões',
            descricao: 'Escolha as questões que vão compor a prova',
            onTap: () => abrirSelecaoQuestoes(context),
          ),
        ],
      ),
    );
  }
}

class MenuCard extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String descricao;
  final VoidCallback onTap;

  const MenuCard({
    super.key,
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),

          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),

        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,

              decoration: BoxDecoration(
                color: const Color(0xFFEFF2FF),
                borderRadius: BorderRadius.circular(16),
              ),

              child: Icon(
                icone,
                color: const Color(0xFF6545E8),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    titulo,

                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    descricao,

                    style: const TextStyle(
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }
}
