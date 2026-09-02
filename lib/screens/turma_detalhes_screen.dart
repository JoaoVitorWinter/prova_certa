import 'package:flutter/material.dart';

import '../models/aluno.dart';
import '../models/turma.dart';
import 'importar_alunos_screen.dart';

class TurmaDetalhesScreen extends StatelessWidget {
  final Turma turma;

  const TurmaDetalhesScreen({
    super.key,
    required this.turma,
  });

  void abrirImportacao(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return const ImportarAlunosModal();
      },
    );
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

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              turma.nome,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),

            Text(
              '${turma.ano} · ${turma.periodo} · '
              '${turma.alunos.length} alunos',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),

            child: TextButton(
              onPressed: () => abrirImportacao(context),

              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6545E8),
                backgroundColor: const Color(0xFFEFF2FF),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),

              child: const Text(
                'Importar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(14),

        children: [
          Row(
            children: [
              Expanded(
                child: InfoCard(
                  valor: turma.nome,
                  titulo: 'Turma',
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: InfoCard(
                  valor: '${turma.alunos.length}',
                  titulo: 'Alunos',
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: InfoCard(
                  valor: turma.periodo,
                  titulo: 'Turno',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
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
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),

                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Lista de alunos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      Text(
                        '${turma.alunos.length} carregados',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: turma.alunos.length,

                  separatorBuilder: (context, index) {
                    return const Divider(height: 1);
                  },

                  itemBuilder: (context, index) {
                    return AlunoItem(
                      aluno: turma.alunos[index],
                      index: index,
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),

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
                  'Importar alunos',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Importe a lista de alunos a partir de uma '
                  'planilha Excel (.xlsx) ou CSV com as colunas: RA, Nome.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,

                  child: OutlinedButton(
                    onPressed: () => abrirImportacao(context),

                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6545E8),

                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),

                      side: const BorderSide(
                        color: Color(0xFF8B7CF6),
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),

                    child: const Text(
                      'Selecionar arquivo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String valor;
  final String titulo;

  const InfoCard({
    super.key,
    required this.valor,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            valor,
            textAlign: TextAlign.center,

            style: const TextStyle(
              color: Color(0xFF6545E8),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            titulo,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

class AlunoItem extends StatelessWidget {
  final Aluno aluno;
  final int index;

  const AlunoItem({
    super.key,
    required this.aluno,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),

      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: corAluno(index),

            child: Text(
              iniciais(aluno.nome),

              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  aluno.nome,

                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  'RA: ${aluno.ra}',

                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,

            decoration: const BoxDecoration(
              color: Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.check,
              color: Color(0xFF059669),
              size: 17,
            ),
          ),
        ],
      ),
    );
  }

  String iniciais(String nome) {
    final partes = nome.trim().split(' ');

    if (partes.length == 1) {
      return partes.first[0].toUpperCase();
    }

    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  Color corAluno(int index) {
    const cores = [
      Color(0xFF5844E8),
      Color(0xFF9333EA),
      Color(0xFF059669),
      Color(0xFF0891B2),
      Color(0xFFEF2D2D),
      Color(0xFFE8790C),
    ];

    return cores[index % cores.length];
  }
}