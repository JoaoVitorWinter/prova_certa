import 'package:flutter/material.dart';

import '../services/theme_service.dart';

class AppearanceScreen extends StatefulWidget {
  final ThemeService? themeService;

  const AppearanceScreen({super.key, this.themeService});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  late final ThemeService _service;

  @override
  void initState() {
    super.initState();
    _service = widget.themeService ?? ThemeService.instancia;
    _service.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedTheme = _service.temaAtualNome;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FB),
      appBar: _appBar(context, isDark: isDark),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(23, 20, 23, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TEMA DO APLICATIVO',
              style: TextStyle(
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF58677D),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: .3,
              ),
            ),
            const SizedBox(height: 11),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? null
                    : const [
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
                    subtitle: 'Mantém o visual padrão com fundo claro',
                    selected: selectedTheme == 'Claro',
                    isDark: isDark,
                    onTap: () => _service.definirTema('Claro'),
                  ),
                  _Divider(isDark: isDark),
                  _ThemeOption(
                    icon: Icons.dark_mode_rounded,
                    title: 'Escuro',
                    subtitle: 'Interface escura com alto contraste',
                    selected: selectedTheme == 'Escuro',
                    isDark: isDark,
                    onTap: () => _service.definirTema('Escuro'),
                  ),
                  _Divider(isDark: isDark),
                  _ThemeOption(
                    icon: Icons.settings_brightness_rounded,
                    title: 'Usar padrão do sistema',
                    subtitle: 'Acompanha a configuração do dispositivo',
                    selected: selectedTheme == 'Sistema',
                    isDark: isDark,
                    onTap: () => _service.definirTema('Sistema'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            Text(
              'A preferência é salva no dispositivo e aplicada automaticamente em todas as telas.',
              style: TextStyle(
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF98A4B6),
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
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF312E81) : const Color(0xFFF0EDFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color:
                    isDark ? const Color(0xFFA5B4FC) : const Color(0xFF6542ED),
                size: 20,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF111827),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF98A4B6),
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
                      ? (isDark
                          ? const Color(0xFFA5B4FC)
                          : const Color(0xFF5B43EF))
                      : (isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFFD4DAE4)),
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFFA5B4FC)
                              : const Color(0xFF5B43EF),
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
  final bool isDark;

  const _Divider({this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 63,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFF0F2F6),
    );
  }
}

PreferredSizeWidget _appBar(BuildContext context, {required bool isDark}) {
  return AppBar(
    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
    surfaceTintColor: isDark ? const Color(0xFF1E293B) : Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    leading: IconButton(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
    ),
    titleSpacing: 0,
    title: Text(
      'Aparência',
      style: TextStyle(
        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Divider(
        height: 1,
        color: isDark ? const Color(0xFF334155) : const Color(0xFFE4E9F1),
      ),
    ),
  );
}
