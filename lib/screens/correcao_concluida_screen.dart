import 'package:flutter/material.dart';

import '../models/prova.dart';

class CorrecaoConcluidaScreen extends StatelessWidget {
  final Prova prova;
  final int folhasCorrigidas;
  final int totalAcertos;
  final int totalQuestoes;

  const CorrecaoConcluidaScreen({
    super.key,
    required this.prova,
    required this.folhasCorrigidas,
    required this.totalAcertos,
    required this.totalQuestoes,
  });

  double get percentual {
    if (totalQuestoes == 0) return 0;
    return (totalAcertos / totalQuestoes) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 25),
                child: Column(
                  children: [
                    const SizedBox(height: 25),
                    _buildSuccessIcon(),
                    const SizedBox(height: 20),
                    const Text(
                      'Correção concluída!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF101827),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'A prova ${prova.nome} foi corrigida com sucesso.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF7B8799),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 27),
                    _buildResumo(),
                    const SizedBox(height: 18),
                    _buildInfoCard(),
                  ],
                ),
              ),
            ),
            _buildButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 57,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE4E9F1),
          ),
        ),
      ),
      alignment: Alignment.centerLeft,
      child: const Text(
        'Correção',
        style: TextStyle(
          color: Color(0xFF101827),
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 78,
      height: 78,
      decoration: const BoxDecoration(
        color: Color(0xFFDDF8EC),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_rounded,
        color: Color(0xFF12A471),
        size: 48,
      ),
    );
  }

  Widget _buildResumo() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '$folhasCorrigidas',
            label: 'Folhas corrigidas',
            icon: Icons.description_outlined,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _StatCard(
            value: '$totalAcertos',
            label: 'Acertos',
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _StatCard(
            value: '${percentual.round()}%',
            label: 'Aproveitamento',
            icon: Icons.analytics_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE3E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo da correção',
            style: TextStyle(
              color: Color(0xFF1A2435),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Prova',
            value: prova.nome,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Questões avaliadas',
            value: '$totalQuestoes',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Questões corretas',
            value: '$totalAcertos',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Questões incorretas',
            value: '${totalQuestoes - totalAcertos}',
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Resultados completos disponíveis em breve.',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5647E8),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Ver resultados completos',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: () {
                Navigator.popUntil(
                  context,
                  (route) => route.isFirst,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5647E8),
                side: const BorderSide(
                  color: Color(0xFFBFC5FF),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Corrigir outra prova',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 105,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFE3E8F0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFF5747E8),
            size: 21,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF172033),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8994A6),
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7F8B9D),
              fontSize: 10,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF263247),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}