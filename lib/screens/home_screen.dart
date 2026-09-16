import 'package:flutter/material.dart';

import 'banco_questoes_screen.dart';
import 'nova_prova_screen.dart';
import 'provas_screen.dart';
import 'resultados_screen.dart';
import 'turmas_screen.dart';
import 'corrigir_prova_screen.dart';
import 'profile_screen.dart';
import '../widgets/app_bottom_navigation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _HomeHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(23, 19, 23, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AÇÕES RÁPIDAS',
                      style: TextStyle(
                        color: Color(0xFF52647C),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .4,
                      ),
                    ),
                    SizedBox(height: 13),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.crop_free_rounded,
                            iconColor: const Color(0xFF4B43F5),
                            iconBackground: const Color(0xFFE9EDFF),
                            title: 'Corrigir prova',
                            subtitle: 'Escaneie a folha',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CorrigirProvaScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 13),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.add_rounded,
                            iconColor: Color(0xFF8047F5),
                            iconBackground: Color(0xFFF1EEFF),
                            title: 'Criar prova',
                            subtitle: 'Nova avaliação',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NovaProvaScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.bar_chart_rounded,
                            iconColor: Color(0xFF009CC0),
                            iconBackground: Color(0xFFE0F7FB),
                            title: 'Ver resultados',
                            subtitle: 'Estatísticas',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ResultadosScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 13),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.receipt_long_outlined,
                            iconColor: Color(0xFF00A978),
                            iconBackground: Color(0xFFD9F8E9),
                            title: 'Banco de questões',
                            subtitle: 'Gerenciar questões',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const BancoQuestoesScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 19),
                    _RecentHeader(),
                    SizedBox(height: 11),
                    _AssessmentCard(
                      icon: Icons.check_rounded,
                      iconColor: Color(0xFF009B69),
                      iconBackground: Color(0xFFD1F8E5),
                      title: '1ª Prova Bimestral — Cito...',
                      details: '1º A · 2026-08-15',
                      status: 'Encerrada',
                      statusColor: Color(0xFFBFF3D9),
                      progressColor: Color(0xFF00A879),
                      score: '36/38',
                      progress: .95,
                    ),
                    SizedBox(height: 10),
                    _AssessmentCard(
                      icon: Icons.hourglass_bottom_rounded,
                      iconColor: Color(0xFF6582D6),
                      iconBackground: Color(0xFFEAF0FF),
                      title: '2ª Prova Bimestral — Genética',
                      details: '1º A · 2026-09-20',
                      status: 'Ativa',
                      statusColor: Color(0xFFDCE8FF),
                      progressColor: Color(0xFF4A58F4),
                      score: '12/38',
                      progress: .32,
                    ),
                  ],
                ),
              ),
            ),
            AppBottomNavigation(
              currentItem: AppNavigationItem.inicio,
              onProvas: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProvasScreen()),
              ),
              onCorrigir: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const CorrigirProvaScreen(),
                ),
              ),
              onResultados: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ResultadosScreen(),
                ),
              ),
              onTurmas: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const TurmasScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(23, 17, 19, 15),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF5642E8), Color(0xFF7B34ED)]),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Boa noite,',
                    style: TextStyle(color: Color(0xFFDCD7FF), fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Prof. Ana Paula',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'E.E. Prof. Antônio Lemos',
                    style: TextStyle(color: Color(0xFFC7C2F8), fontSize: 11),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: 43,
                height: 43,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x385F4BEE),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  'AP',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 19),
        const Row(
          children: [
            Expanded(
              child: _Metric(
                value: '1',
                label: 'Provas ativas',
                color: Color(0xFFFFE15B),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _Metric(
                value: '80',
                label: 'Corrigidas',
                color: Color(0xFF5FEAC1),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _Metric(
                value: '145',
                label: 'Alunos',
                color: Color(0xFFB8B9FF),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _Metric({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 69,
    decoration: BoxDecoration(
      color: const Color(0x287D6BEB),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFD5D1FF), fontSize: 11),
        ),
      ],
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(15),
    child: Container(
      height: 114,
      padding: const EdgeInsets.fromLTRB(15, 14, 9, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF101827),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF8995A8), fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

class _RecentHeader extends StatelessWidget {
  const _RecentHeader();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        'AVALIAÇÕES RECENTES',
        style: TextStyle(
          color: Color(0xFF52647C),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: .4,
        ),
      ),
      Text(
        'Ver todas',
        style: TextStyle(
          color: Color(0xFF5537E8),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _AssessmentCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String details;
  final String status;
  final Color statusColor;
  final Color progressColor;
  final String score;
  final double progress;

  const _AssessmentCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.details,
    required this.status,
    required this.statusColor,
    required this.progressColor,
    required this.score,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 83,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D1B2740),
          blurRadius: 5,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF101827),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  _Status(text: status, color: statusColor),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                details,
                style: const TextStyle(color: Color(0xFF77869E), fontSize: 10),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      backgroundColor: const Color(0xFFE9EDF4),
                      color: progressColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    score,
                    style: const TextStyle(
                      color: Color(0xFF8793A8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Status extends StatelessWidget {
  final String text;
  final Color color;

  const _Status({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF087454),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
