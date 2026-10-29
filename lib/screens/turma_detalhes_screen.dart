import 'package:flutter/material.dart';

import '../models/aluno.dart';
import '../models/turma.dart';
import '../services/turma_service.dart';
import '../utils/validadores.dart';
import '../widgets/app_bottom_navigation.dart';
import 'corrigir_prova_screen.dart';
import 'home_screen.dart';
import 'importar_alunos_screen.dart';
import 'nova_turma_screen.dart';
import 'provas_screen.dart';
import 'resultados_screen.dart';

class TurmaDetalhesScreen extends StatefulWidget {
  final Turma turma;
  final TurmaService? turmaService;

  const TurmaDetalhesScreen({
    super.key,
    required this.turma,
    this.turmaService,
  });

  @override
  State<TurmaDetalhesScreen> createState() => _TurmaDetalhesScreenState();
}

class _TurmaDetalhesScreenState extends State<TurmaDetalhesScreen> {
  late final TurmaService _turmaService;

  @override
  void initState() {
    super.initState();
    _turmaService = widget.turmaService ?? TurmaService();
  }

  void abrirImportacao(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ImportarAlunosModal(
          turmaId: widget.turma.id,
          turmaService: _turmaService,
        );
      },
    );
  }

  Future<void> _abrirEdicaoTurma(Turma turmaAtual) async {
    final atualizada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => NovaTurmaScreen(
          turmaParaEditar: turmaAtual,
          turmaService: _turmaService,
        ),
      ),
    );

    if (atualizada == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Turma atualizada com sucesso.'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _modalAdicionarOuEditarAluno(
    BuildContext context,
    String turmaId, {
    Aluno? aluno,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _AlunoFormModal(
          turmaId: turmaId,
          aluno: aluno,
          turmaService: _turmaService,
        );
      },
    );
  }

  Future<void> _confirmarRemocaoAluno(
    String turmaId,
    Aluno aluno,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover aluno'),
        content: Text(
          'Deseja remover "${aluno.nome}" (RA: ${aluno.ra}) desta turma? '
          'A contagem de alunos será atualizada automaticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      try {
        await _turmaService.removerAluno(
          turmaId: turmaId,
          alunoId: aluno.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aluno removido com sucesso.'),
              backgroundColor: Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao remover aluno: $e'),
              backgroundColor: const Color(0xFFD32F2F),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Turma?>(
      stream: _turmaService.monitorarTurma(widget.turma.id),
      initialData: widget.turma,
      builder: (context, turmaSnapshot) {
        final turma = turmaSnapshot.data ?? widget.turma;

        return StreamBuilder<List<Aluno>>(
          stream: _turmaService.monitorarAlunos(turmaId: turma.id),
          builder: (context, alunosSnapshot) {
            final alunos = alunosSnapshot.data;
            final totalAlunos = alunos?.length ?? turma.totalAlunos;

            return Scaffold(
              backgroundColor: const Color(0xFFF4F6FA),
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                iconTheme: const IconThemeData(color: Color(0xFF6545E8)),
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
                      '$totalAlunos alunos',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Editar turma',
                    onPressed: () => _abrirEdicaoTurma(turma),
                  ),
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
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(14),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child:
                                  InfoCard(valor: turma.nome, titulo: 'Turma'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InfoCard(
                                valor: '$totalAlunos',
                                titulo: 'Alunos',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InfoCard(
                                  valor: turma.periodo, titulo: 'Turno'),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 12, 12),
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
                                    TextButton.icon(
                                      onPressed: () =>
                                          _modalAdicionarOuEditarAluno(
                                        context,
                                        turma.id,
                                      ),
                                      icon: const Icon(
                                        Icons.person_add_alt_1_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Adicionar'),
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFF6545E8),
                                        backgroundColor:
                                            const Color(0xFFEFF2FF),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              _buildAlunosContent(
                                context,
                                turma.id,
                                alunosSnapshot,
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
                                        vertical: 16),
                                    side: const BorderSide(
                                      color: Color(0xFF8B7CF6),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Selecionar arquivo',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppBottomNavigation(
                    currentItem: AppNavigationItem.turmas,
                    onInicio: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    },
                    onProvas: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProvasScreen(),
                        ),
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
          },
        );
      },
    );
  }

  Widget _buildAlunosContent(
    BuildContext context,
    String turmaId,
    AsyncSnapshot<List<Aluno>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6545E8),
          ),
        ),
      );
    }

    if (snapshot.hasError) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFE53935),
                size: 36,
              ),
              const SizedBox(height: 8),
              const Text(
                'Não foi possível carregar os alunos.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final alunos = snapshot.data ?? [];

    if (alunos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.groups_outlined,
                size: 44,
                color: Color(0xFFB0BAC8),
              ),
              const SizedBox(height: 10),
              const Text(
                'Nenhum aluno cadastrado nesta turma',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Cadastre os alunos manualmente ou importe uma planilha.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () =>
                    _modalAdicionarOuEditarAluno(context, turmaId),
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Cadastrar primeiro aluno'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6545E8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: alunos.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final aluno = alunos[index];
        return AlunoItem(
          aluno: aluno,
          index: index,
          onEditar: () => _modalAdicionarOuEditarAluno(
            context,
            turmaId,
            aluno: aluno,
          ),
          onRemover: () => _confirmarRemocaoAluno(
            turmaId,
            aluno,
          ),
        );
      },
    );
  }
}

class _AlunoFormModal extends StatefulWidget {
  final String turmaId;
  final Aluno? aluno;
  final TurmaService turmaService;

  const _AlunoFormModal({
    required this.turmaId,
    this.aluno,
    required this.turmaService,
  });

  @override
  State<_AlunoFormModal> createState() => _AlunoFormModalState();
}

class _AlunoFormModalState extends State<_AlunoFormModal> {
  late final TextEditingController _nomeController;
  late final TextEditingController _raController;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.aluno?.nome ?? '');
    _raController = TextEditingController(text: widget.aluno?.ra ?? '');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _raController.dispose();
    super.dispose();
  }

  Future<void> _submeter() async {
    final nome = _nomeController.text.trim();
    final ra = _raController.text.trim();

    final erro = Validadores.nomeAluno(nome) ?? Validadores.ra(ra);
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      if (widget.aluno != null) {
        await widget.turmaService.editarAluno(
          turmaId: widget.turmaId,
          alunoId: widget.aluno!.id,
          nome: nome,
          ra: ra,
        );
      } else {
        await widget.turmaService.cadastrarAluno(
          turmaId: widget.turmaId,
          nome: nome,
          ra: ra,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.aluno != null
                  ? 'Aluno atualizado com sucesso.'
                  : 'Aluno cadastrado com sucesso.',
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = e
              .toString()
              .replaceFirst('Exception: ', '')
              .replaceFirst('ArgumentError: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ehEdicao = widget.aluno != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ehEdicao ? 'Editar aluno' : 'Novo aluno',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            ehEdicao
                ? 'Atualize o nome e o RA do aluno.'
                : 'Informe os dados do aluno para cadastrá-lo na turma.',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 18),
          const Text(
            'Nome completo',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nomeController,
            enabled: !_salvando,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration('Ex: Gabriel Alves Santos'),
          ),
          const SizedBox(height: 14),
          const Text(
            'Registro do Aluno (RA)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _raController,
            enabled: !_salvando,
            keyboardType: TextInputType.text,
            decoration: _inputDecoration('Ex: 001234'),
          ),
          if (_erro != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _erro!,
                style: const TextStyle(
                  color: Color(0xFFC62828),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _salvando ? null : _submeter,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6545E8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _salvando
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      ehEdicao ? 'Salvar alterações' : 'Cadastrar aluno',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6545E8), width: 1.5),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String valor;
  final String titulo;

  const InfoCard({super.key, required this.valor, required this.titulo});

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
          Text(titulo, style: const TextStyle(color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

class AlunoItem extends StatelessWidget {
  final Aluno aluno;
  final int index;
  final VoidCallback? onEditar;
  final VoidCallback? onRemover;

  const AlunoItem({
    super.key,
    required this.aluno,
    required this.index,
    this.onEditar,
    this.onRemover,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEditar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
              onSelected: (value) {
                if (value == 'editar') {
                  onEditar?.call();
                } else if (value == 'remover') {
                  onRemover?.call();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'editar',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remover',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 18, color: Color(0xFFE53935)),
                      SizedBox(width: 8),
                      Text('Remover',
                          style: TextStyle(color: Color(0xFFE53935))),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String iniciais(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return 'A';
    if (partes.length == 1) return partes.first[0].toUpperCase();
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
