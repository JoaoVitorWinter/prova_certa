import 'package:flutter/material.dart';

import '../mocks/turmas_mock.dart';
import 'turma_detalhes_screen.dart';
import 'nova_turma_screen.dart';

class TurmasScreen extends StatelessWidget {
  const TurmasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final totalAlunos = turmasMock.fold<int>(
      0,
      (total, turma) => total + turma.alunos.length,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Turmas',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () async {
                final criada = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const NovaTurmaScreen(),
                  ),
                );

                if (criada == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Turma criada com sucesso.',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Nova'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6545E8),
                backgroundColor: const Color(0xFFEFF2FF),
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),

          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ResumoCard(
                      valor: '${turmasMock.length}',
                      titulo: 'Turmas ativas',
                      cor: const Color(0xFF6545E8),
                      fundo: const Color(0xFFEFF2FF),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _ResumoCard(
                      valor: '$totalAlunos',
                      titulo: 'Total de alunos',
                      cor: const Color(0xFF00A56A),
                      fundo: const Color(0xFFD5F7E8),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Expanded(
                child: ListView.separated(
                  itemCount: turmasMock.length,

                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),

                  itemBuilder: (context, index) {
                    final turma = turmasMock[index];

                    return InkWell(
                      borderRadius: BorderRadius.circular(20),

                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TurmaDetalhesScreen(turma: turma),
                          ),
                        );
                      },

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
                              width: 58,
                              height: 58,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF2FF),
                                borderRadius: BorderRadius.circular(18),
                              ),

                              child: Text(
                                turma.nome,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF6545E8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                children: [
                                  Text(
                                    '${turma.nome} — ${turma.ano}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  Text(
                                    '${turma.disciplina} · ${turma.periodo}',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  Text(
                                    '${turma.alunos.length} alunos cadastrados',
                                    style: const TextStyle(
                                      color: Color(0xFF00A56A),
                                      fontWeight: FontWeight.w600,
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
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumoCard extends StatelessWidget {
  final String valor;
  final String titulo;
  final Color cor;
  final Color fundo;

  const _ResumoCard({
    required this.valor,
    required this.titulo,
    required this.cor,
    required this.fundo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,

      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            valor,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            titulo,
            style: TextStyle(
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}