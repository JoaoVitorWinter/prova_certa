import 'package:flutter/material.dart';

enum AppNavigationItem { inicio, provas, corrigir, resultados, turmas }

class AppBottomNavigation extends StatelessWidget {
  final AppNavigationItem currentItem;
  final VoidCallback? onProvas;
  final VoidCallback? onTurmas;

  const AppBottomNavigation({
    super.key,
    required this.currentItem,
    this.onProvas,
    this.onTurmas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E9F1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavigationItem(
            icon: Icons.home_outlined,
            label: 'Início',
            selected: currentItem == AppNavigationItem.inicio,
          ),
          _NavigationItem(
            icon: Icons.description_outlined,
            label: 'Provas',
            selected: currentItem == AppNavigationItem.provas,
            onTap: onProvas,
          ),
          _NavigationItem(
            icon: Icons.document_scanner_outlined,
            label: 'Corrigir',
            selected: currentItem == AppNavigationItem.corrigir,
          ),
          _NavigationItem(
            icon: Icons.bar_chart_outlined,
            label: 'Resultados',
            selected: currentItem == AppNavigationItem.resultados,
          ),
          _NavigationItem(
            icon: Icons.people_outline_rounded,
            label: 'Turmas',
            selected: currentItem == AppNavigationItem.turmas,
            onTap: onTurmas,
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF5146EE) : const Color(0xFF91A1B8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 55,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
