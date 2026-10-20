import 'package:flutter/material.dart';

import '../models/turma.dart';
import '../services/turma_service.dart';
import '../widgets/app_bottom_navigation.dart';
import 'corrigir_prova_screen.dart';
import 'home_screen.dart';
import 'nova_turma_screen.dart';
import 'provas_screen.dart';
import 'resultados_screen.dart';
import 'turma_detalhes_screen.dart';

class TurmasScreen extends StatefulWidget {
  final TurmaService? turmaService;

  const TurmasScreen({super.key, this.turmaService});

  @override
  State<TurmasScreen> createState() => _TurmasScreenState();
}

class _TurmasScreenState extends State<TurmasScreen> {
  late final TurmaService _turmaService;

  @override
  void initState() {
    super.initState();
    _turmaService = widget.turmaService ?? TurmaService();
  }

  Future<void> _abrirNovaTurma() async {
    final criada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => NovaTurmaScreen(turmaService: _turmaService),
      ),
    );

    if (criada == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Turma criada com sucesso.'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
              onPressed: () => _abrirNovaTurma(),
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
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: StreamBuilder<List<Turma>>(
                stream: _turmaService.monitorarTurmas(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6545E8),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: Color(0xFFE53935),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Não foi possível carregar as turmas.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => setState(() {}),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6545E8),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final turmas = snapshot.data ?? [];

                  final totalAlunos = turmas.fold<int>(
                    0,
                    (total, turma) => total + turma.totalAlunos,
                  );

                  return Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _ResumoCard(
                                valor: '${turmas.length}',
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
                          child: turmas.isEmpty
                              ? _buildEmptyState(context)
                              : ListView.separated(
                                  itemCount: turmas.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 14),
                                  itemBuilder: (context, index) {
                                    final turma = turmas[index];
                                    return _buildTurmaCard(context, turma);
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          AppBottomNavigation(
            currentItem: AppNavigationItem.turmas,
            onInicio: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
            onProvas: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProvasScreen()),
              );
            },
            onCorrigir: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const CorrigirProvaScreen(),
                ),
              );
            },
            onResultados: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ResultadosScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.school_outlined,
              size: 40,
              color: Color(0xFF6545E8),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma turma cadastrada',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Toque em "Nova" para cadastrar sua primeira turma.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => _abrirNovaTurma(),
            icon: const Icon(Icons.add),
            label: const Text('Criar turma'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6545E8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurmaCard(BuildContext context, Turma turma) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TurmaDetalhesScreen(
              turma: turma,
              turmaService: _turmaService,
            ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    '${turma.totalAlunos} alunos cadastrados',
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
          Text(titulo, style: TextStyle(color: cor)),
        ],
      ),
    );
  }
}
