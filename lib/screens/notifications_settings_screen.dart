import 'package:flutter/material.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _provas = true;
  bool _correcoes = true;
  bool _resultados = true;
  bool _avisos = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _appBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(23, 20, 23, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escolha quais avisos você quer receber no aplicativo.',
              style: TextStyle(
                color: Color(0xFF74849B),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
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
                children: [
                  _NotificationTile(
                    icon: Icons.description_outlined,
                    title: 'Provas e avaliações',
                    subtitle: 'Criação, alterações e lembretes de provas',
                    value: _provas,
                    onChanged: (value) => setState(() => _provas = value),
                  ),
                  const _SettingsDivider(),
                  _NotificationTile(
                    icon: Icons.document_scanner_outlined,
                    title: 'Correções',
                    subtitle: 'Avisos sobre correções concluídas',
                    value: _correcoes,
                    onChanged: (value) => setState(() => _correcoes = value),
                  ),
                  const _SettingsDivider(),
                  _NotificationTile(
                    icon: Icons.bar_chart_rounded,
                    title: 'Resultados',
                    subtitle: 'Atualizações de desempenho e resultados',
                    value: _resultados,
                    onChanged: (value) => setState(() => _resultados = value),
                  ),
                  const _SettingsDivider(),
                  _NotificationTile(
                    icon: Icons.campaign_outlined,
                    title: 'Avisos do sistema',
                    subtitle: 'Novidades e comunicados importantes',
                    value: _avisos,
                    onChanged: (value) => setState(() => _avisos = value),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF6542ED), size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF98A4B6),
                    fontSize: 9,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF5B43EF),
            activeTrackColor: const Color(0xFFCEC8FF),
          ),
        ],
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 63, color: Color(0xFFF0F2F6));
  }
}

PreferredSizeWidget _appBar(BuildContext context) {
  return AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    leading: IconButton(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
      color: const Color(0xFF111827),
    ),
    titleSpacing: 0,
    title: const Text(
      'Notificações',
      style: TextStyle(
        color: Color(0xFF111827),
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(1),
      child: Divider(height: 1, color: Color(0xFFE4E9F1)),
    ),
  );
}
