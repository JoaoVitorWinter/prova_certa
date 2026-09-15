import 'package:flutter/material.dart';

import 'about_app_screen.dart';
import 'appearance_screen.dart';
import 'edit_profile_screen.dart';
import 'notifications_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 58,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 23),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE4E9F1)),
                ),
              ),
              child: const Text(
                'Perfil',
                style: TextStyle(
                  color: Color(0xFF101827),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(23, 14, 23, 24),
                child: Column(
                  children: [
                    const _ProfileCard(),
                    const SizedBox(height: 13),
                    const Row(
                      children: [
                        Expanded(
                          child: _StatCard(value: '4', label: 'Turmas'),
                        ),
                        SizedBox(width: 7),
                        Expanded(
                          child: _StatCard(value: '4', label: 'Provas'),
                        ),
                        SizedBox(width: 7),
                        Expanded(
                          child: _StatCard(value: '10', label: 'Questões'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SettingsCard(
                      items: [
                        _SettingsItemData(
                          icon: Icons.person_rounded,
                          iconColor: const Color(0xFF6D3BAA),
                          title: 'Editar perfil',
                          subtitle: 'Nome e informações pessoais',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          ),
                        ),
                        _SettingsItemData(
                          icon: Icons.notifications_rounded,
                          iconColor: const Color(0xFFF0A536),
                          title: 'Notificações',
                          subtitle: 'Alertas e avisos do sistema',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const NotificationsSettingsScreen(),
                            ),
                          ),
                        ),
                        _SettingsItemData(
                          icon: Icons.palette_rounded,
                          iconColor: const Color(0xFFFF6F91),
                          title: 'Aparência',
                          subtitle: 'Tema claro / escuro',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AppearanceScreen(),
                            ),
                          ),
                        ),
                        _SettingsItemData(
                          icon: Icons.apps_rounded,
                          iconColor: const Color(0xFF3853AF),
                          title: 'Sobre o app',
                          subtitle: 'AvaliaPro 1.0.0 — N1 Protótipo',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AboutAppScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 18),
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
      child: const Column(
        children: [
          _Avatar(),
          SizedBox(height: 10),
          Text(
            'Prof. Ana Paula Santos',
            style: TextStyle(
              color: Color(0xFF101827),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'ana.santos@escola.edu.br',
            style: TextStyle(color: Color(0xFF7988A0), fontSize: 11),
          ),
          SizedBox(height: 7),
          _SchoolBadge(),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5D48F2), Color(0xFF7B2EEB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(19),
      ),
      child: const Text(
        'AP',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SchoolBadge extends StatelessWidget {
  const _SchoolBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'E.E. Prof. Antônio Lemos',
        style: TextStyle(
          color: Color(0xFF6849E8),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF5A43EF),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFA0A9BA), fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<_SettingsItemData> items;

  const _SettingsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Text(
              'Configurações',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8ECF2)),
          for (var index = 0; index < items.length; index++) ...[
            _SettingsItem(data: items[index]),
            if (index != items.length - 1)
              const Divider(
                height: 1,
                indent: 45,
                color: Color(0xFFF0F2F6),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final _SettingsItemData data;

  const _SettingsItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Icon(data.icon, color: data.iconColor, size: 18),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.subtitle,
                    style: const TextStyle(
                      color: Color(0xFFA1ACC0),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFD2D9E4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsItemData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _SettingsItemData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
