import 'dart:async';

import 'package:flutter/material.dart';

import '../models/prova.dart';
import '../models/turma.dart';
import '../services/prova_service.dart';
import '../services/turma_service.dart';
import '../widgets/app_bottom_navigation.dart';
import 'home_screen.dart';
import 'nova_prova_screen.dart';
import 'resultados_screen.dart';
import 'turmas_screen.dart';
import 'corrigir_prova_screen.dart';
import 'qr_prova_screen.dart';

class ProvasScreen extends StatefulWidget {
  final ProvaService? provaService;
  final TurmaService? turmaService;

  const ProvasScreen({super.key, this.provaService, this.turmaService});

  @override
  State<ProvasScreen> createState() => _ProvasScreenState();
}

class _ProvasScreenState extends State<ProvasScreen> {
  late final ProvaService _provaService;
  late final TurmaService _turmaService;
  StreamSubscription<List<Prova>>? _provasSub;
  StreamSubscription<List<Turma>>? _turmasSub;

  List<Prova> _provas = [];
  Map<String, int> _alunosPorTurma = {};
  bool _carregando = true;
  Object? _erro;
  ProvaStatus? _filtro;

  List<Prova> get _provasFiltradas {
    if (_filtro == null) return _provas;
    return _provas.where((prova) => prova.status == _filtro).toList();
  }

  @override
  void initState() {
    super.initState();
    _provaService = widget.provaService ?? ProvaService();
    _turmaService = widget.turmaService ?? TurmaService();
    _escutarProvas();
    _turmasSub = _turmaService.monitorarTurmas().listen(
      (turmas) => setState(() {
        _alunosPorTurma = {
          for (final turma in turmas) turma.id: turma.totalAlunos,
        };
      }),
      onError: (Object _) {},
    );
  }

  @override
  void dispose() {
    _provasSub?.cancel();
    _turmasSub?.cancel();
    super.dispose();
  }

  void _escutarProvas() {
    _provasSub?.cancel();
    _provasSub = _provaService.monitorarProvas().listen(
      (provas) => setState(() {
        _provas = provas;
        _carregando = false;
      }),
      onError: (Object e) => setState(() {
        _erro = e;
        _carregando = false;
      }),
      onDone: () {
        if (mounted && _carregando) {
          setState(() => _carregando = false);
        }
      },
    );
  }

  _ProvaStats _statsFor(Prova prova) {
    final corrigidas =
        (prova.resumoResultado?['totalFolhasCorrigidas'] as num?)?.toInt() ?? 0;
    final alunos = _alunosPorTurma[prova.turma.id] ?? corrigidas;
    final pendentes = alunos > corrigidas ? alunos - corrigidas : 0;

    return _ProvaStats(
      corrected: corrigidas,
      total: alunos,
      pending: pendentes,
      progress: alunos == 0 ? 0 : (corrigidas / alunos).clamp(0, 1).toDouble(),
    );
  }

  void _mostrarMensagem(String mensagem, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? const Color(0xFFD32F2F) : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _alterarStatus(Prova prova, ProvaStatus status) async {
    try {
      await _provaService.atualizarStatus(prova.id, status);
      if (!mounted) return;
      _mostrarMensagem(
        'Prova marcada como ${_statusStyle(status).label.toLowerCase()}.',
      );
    } catch (e) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível atualizar a prova: $e', erro: true);
    }
  }

  Future<void> _excluir(Prova prova) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Excluir prova',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'A prova "${prova.nome}" e os resultados das correções serão '
          'removidos. Deseja continuar?',
          style: const TextStyle(color: Color(0xFF64748B), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Excluir',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await _provaService.excluirProva(prova.id);
      if (!mounted) return;
      _mostrarMensagem('Prova excluída.');
    } catch (e) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível excluir a prova: $e', erro: true);
    }
  }

  Future<void> _abrirAcoes(Prova prova) async {
    final acoes = <({String label, IconData icon, ProvaStatus status})>[
      if (prova.status == ProvaStatus.rascunho)
        (
          label: 'Publicar prova',
          icon: Icons.publish_rounded,
          status: ProvaStatus.ativa,
        ),
      if (prova.status == ProvaStatus.ativa)
        (
          label: 'Encerrar prova',
          icon: Icons.lock_outline_rounded,
          status: ProvaStatus.encerrada,
        ),
      if (prova.status == ProvaStatus.encerrada)
        (
          label: 'Reabrir prova',
          icon: Icons.lock_open_rounded,
          status: ProvaStatus.ativa,
        ),
    ];

    final escolha = await showModalBottomSheet<Object>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Text(
                prova.nome,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF101827),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.qr_code_2_rounded,
                color: Color(0xFF5146EE),
              ),
              title: const Text('Ver QR Code da prova'),
              subtitle: const Text('Abrir novamente o código desta prova'),
              onTap: () => Navigator.pop(context, 'qr'),
            ),
            for (final acao in acoes)
              ListTile(
                leading: Icon(acao.icon, color: const Color(0xFF5146EE)),
                title: Text(acao.label),
                onTap: () => Navigator.pop(context, acao.status),
              ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
              ),
              title: const Text(
                'Excluir prova',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
              onTap: () => Navigator.pop(context, 'excluir'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted || escolha == null) return;

    if (escolha == 'qr') {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QrProvaScreen(prova: prova),
        ),
      );
    } else if (escolha is ProvaStatus) {
      await _alterarStatus(prova, escolha);
    } else if (escolha == 'excluir') {
      await _excluir(prova);
    }
  }

  Widget _buildConteudo() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5547EA)),
      );
    }

    if (_erro != null) {
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
                'Não foi possível carregar as provas.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$_erro',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _carregando = true;
                    _erro = null;
                  });
                  _escutarProvas();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5547EA),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final provas = _provasFiltradas;

    if (provas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.description_outlined,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(height: 12),
              Text(
                _provas.isEmpty
                    ? 'Nenhuma prova criada'
                    : 'Nenhuma prova neste filtro',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              if (_provas.isEmpty) ...[
                const SizedBox(height: 6),
                const Text(
                  'Toque em "+ Nova" para criar a primeira prova.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(23, 12, 23, 20),
      itemCount: provas.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => InkWell(
        onTap: () => _abrirAcoes(provas[index]),
        borderRadius: BorderRadius.circular(16),
        child: _ProvaCard(
          prova: provas[index],
          stats: _statsFor(provas[index]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              onNewPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NovaProvaScreen(
                      provaService: _provaService,
                      turmaService: _turmaService,
                    ),
                  ),
                );
              },
            ),
            _FilterBar(
              provas: _provas,
              filtroSelecionado: _filtro,
              onFilterSelected: (filtro) => setState(() => _filtro = filtro),
            ),
            Expanded(child: _buildConteudo()),
            AppBottomNavigation(
              currentItem: AppNavigationItem.provas,
              onInicio: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
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
              onTurmas: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const TurmasScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onNewPressed;

  const _Header({required this.onNewPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.fromLTRB(30, 14, 17, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E9F1))),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Minhas Provas',
              style: TextStyle(
                color: Color(0xFF101827),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: onNewPressed,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFEFF2FF),
              foregroundColor: const Color(0xFF5146EE),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: const Text(
              '+ Nova',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final List<Prova> provas;
  final ProvaStatus? filtroSelecionado;
  final ValueChanged<ProvaStatus?> onFilterSelected;

  const _FilterBar({
    required this.provas,
    required this.filtroSelecionado,
    required this.onFilterSelected,
  });

  int _count(ProvaStatus status) =>
      provas.where((prova) => prova.status == status).length;

  @override
  Widget build(BuildContext context) {
    final filtros = <({String label, ProvaStatus? status, int count})>[
      (label: 'Todas', status: null, count: provas.length),
      (
        label: 'Ativas',
        status: ProvaStatus.ativa,
        count: _count(ProvaStatus.ativa),
      ),
      (
        label: 'Encerradas',
        status: ProvaStatus.encerrada,
        count: _count(ProvaStatus.encerrada),
      ),
      (
        label: 'Rascunhos',
        status: ProvaStatus.rascunho,
        count: _count(ProvaStatus.rascunho),
      ),
    ];

    return Container(
      height: 51,
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: filtros.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filtro = filtros[index];
          final selected = filtroSelecionado == filtro.status;
          return _FilterChip(
            label: filtro.label,
            count: filtro.count,
            selected: selected,
            onTap: () => onFilterSelected(filtro.status),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF5547EA) : const Color(0xFFF0F4F8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF51647D),
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0x405D4CF2)
                    : const Color(0xFFE1E7EF),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF8A99AE),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProvaCard extends StatelessWidget {
  final Prova prova;
  final _ProvaStats stats;

  const _ProvaCard({required this.prova, required this.stats});

  @override
  Widget build(BuildContext context) {
    final status = _statusStyle(prova.status);
    final isDraft = prova.status == ProvaStatus.rascunho;

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1B2740),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  prova.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF101827),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(
                label: status.label,
                background: status.background,
                foreground: status.foreground,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${prova.turma.nome} · ${_formatDate(prova.dataAplicacao)}',
            style: const TextStyle(color: Color(0xFF667A96), fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoBox(value: '${prova.quantidadeQuestoes}', label: 'Questões'),
              const SizedBox(width: 7),
              _InfoBox(
                value: '${stats.corrected}/${stats.total}',
                label: 'Corrigidas',
              ),
              const SizedBox(width: 7),
              _InfoBox(value: '${stats.pending}', label: 'Pendentes'),
            ],
          ),
          if (isDraft)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                '⚠ Prova ainda não foi publicada',
                style: TextStyle(color: Color(0xFFB65D2E), fontSize: 11),
              ),
            )
          else ...[
            const SizedBox(height: 11),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Progresso de correção',
                    style: TextStyle(color: Color(0xFF8A99AE), fontSize: 11),
                  ),
                ),
                Text(
                  '${(stats.progress * 100).round()}%',
                  style: TextStyle(
                    color: status.foreground,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            LinearProgressIndicator(
              value: stats.progress,
              minHeight: 4,
              backgroundColor: const Color(0xFFE9EDF4),
              color: status.foreground,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String value;
  final String label;

  const _InfoBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 51,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF182235),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF91A0B5), fontSize: 10),
          ),
        ],
      ),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _StatusBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: foreground,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _ProvaStats {
  final int corrected;
  final int total;
  final int pending;
  final double progress;

  const _ProvaStats({
    required this.corrected,
    required this.total,
    required this.pending,
    required this.progress,
  });
}

({String label, Color background, Color foreground}) _statusStyle(
  ProvaStatus status,
) {
  switch (status) {
    case ProvaStatus.ativa:
      return (
        label: 'Ativa',
        background: const Color(0xFFDCE8FF),
        foreground: const Color(0xFF3A68D3),
      );
    case ProvaStatus.encerrada:
      return (
        label: 'Encerrada',
        background: const Color(0xFFCFF7E3),
        foreground: const Color(0xFF087454),
      );
    case ProvaStatus.rascunho:
      return (
        label: 'Rascunho',
        background: const Color(0xFFFFF0C5),
        foreground: const Color(0xFFB65D2E),
      );
  }
}

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
