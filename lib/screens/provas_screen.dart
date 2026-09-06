import 'package:flutter/material.dart';

import '../mocks/provas_mock.dart';
import '../models/prova.dart';
import '../widgets/app_bottom_navigation.dart';
import 'nova_prova_screen.dart';
import 'turmas_screen.dart';

class ProvasScreen extends StatefulWidget {
  const ProvasScreen({super.key});

  @override
  State<ProvasScreen> createState() => _ProvasScreenState();
}

class _ProvasScreenState extends State<ProvasScreen> {
  ProvaStatus? _filtro;

  List<Prova> get _provasFiltradas {
    if (_filtro == null) return provasMock;
    return provasMock.where((prova) => prova.status == _filtro).toList();
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
                    builder: (context) => const NovaProvaScreen(),
                  ),
                );
              },
            ),
            _FilterBar(
              filtroSelecionado: _filtro,
              onFilterSelected: (filtro) => setState(() => _filtro = filtro),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(23, 12, 23, 20),
                itemCount: _provasFiltradas.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) => _ProvaCard(
                  prova: _provasFiltradas[index],
                  stats: _statsFor(_provasFiltradas[index]),
                ),
              ),
            ),
            AppBottomNavigation(
              currentItem: AppNavigationItem.provas,
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
  final ProvaStatus? filtroSelecionado;
  final ValueChanged<ProvaStatus?> onFilterSelected;

  const _FilterBar({
    required this.filtroSelecionado,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filtros = <({String label, ProvaStatus? status, int count})>[
      (label: 'Todas', status: null, count: provasMock.length),
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
                value: '${stats.corrected}/${prova.quantidadeQuestoes}',
                label: 'Corrigidas',
              ),
              const SizedBox(width: 7),
              _InfoBox(
                value: isDraft
                    ? '${prova.quantidadeQuestoes}'
                    : '${stats.pending}',
                label: isDraft ? 'Pendentes' : 'Pendentes',
              ),
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
  final int pending;
  final double progress;

  const _ProvaStats({
    required this.corrected,
    required this.pending,
    required this.progress,
  });
}

_ProvaStats _statsFor(Prova prova) {
  switch (prova.id) {
    case '1':
      return const _ProvaStats(corrected: 36, pending: 2, progress: .95);
    case '2':
      return const _ProvaStats(corrected: 12, pending: 26, progress: .32);
    case '3':
      return const _ProvaStats(corrected: 0, pending: 15, progress: 0);
    default:
      return const _ProvaStats(corrected: 24, pending: 8, progress: .75);
  }
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

int _count(ProvaStatus status) =>
    provasMock.where((prova) => prova.status == status).length;

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
