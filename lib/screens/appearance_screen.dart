import 'package:flutter/material.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  String _selectedTheme = 'Claro';

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
              'TEMA DO APLICATIVO',
              style: TextStyle(
                color: Color(0xFF58677D),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: .3,
              ),
            ),
            const SizedBox(height: 11),
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
                  _ThemeOption(
                    icon: Icons.light_mode_rounded,
                    title: 'Claro',
                    subtitle: 'Mantém o visual atual do AvaliaPro',
                    selected: _selectedTheme == 'Claro',
                    onTap: () => setState(() => _selectedTheme = 'Claro'),
                  ),
                  const _Divider(),
                  _ThemeOption(
                    icon: Icons.dark_mode_rounded,
                    title: 'Escuro',
                    subtitle: 'Interface com tons escuros',
                    selected: _selectedTheme == 'Escuro',
                    onTap: () => setState(() => _selectedTheme = 'Escuro'),
                  ),
                  const _Divider(),
                  _ThemeOption(
                    icon: Icons.settings_brightness_rounded,
                    title: 'Usar padrão do sistema',
                    subtitle: 'Acompanha a configuração do dispositivo',
                    selected: _selectedTheme == 'Sistema',
                    onTap: () => setState(() => _selectedTheme = 'Sistema'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            const Text(
              'Nesta versão do protótipo a seleção é demonstrativa e fica apenas nesta tela.',
              style: TextStyle(
                color: Color(0xFF98A4B6),
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
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
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF5B43EF)
                      : const Color(0xFFD4DAE4),
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF5B43EF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

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
      'Aparência',
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
