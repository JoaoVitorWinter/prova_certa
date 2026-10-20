import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../models/turma.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../services/turma_service.dart';
import '../widgets/app_bottom_navigation.dart';
import 'about_app_screen.dart';
import 'appearance_screen.dart';
import 'corrigir_prova_screen.dart';
import 'edit_profile_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'notifications_settings_screen.dart';
import 'provas_screen.dart';
import 'resultados_screen.dart';
import 'turmas_screen.dart';

class ProfileScreen extends StatelessWidget {
  final TurmaService? turmaService;

  const ProfileScreen({super.key, this.turmaService});

  void _confirmarLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da conta'),
        content:
            const Text('Deseja realmente encerrar sua sessão no AvaliaPro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

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
                border: Border(bottom: BorderSide(color: Color(0xFFE4E9F1))),
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
                    Row(
                      children: [
                        Expanded(
                          child: _TurmasStatCard(turmaService: turmaService),
                        ),
                        const SizedBox(width: 7),
                        const Expanded(
                          child: _StatCard(value: '4', label: 'Provas'),
                        ),
                        const SizedBox(width: 7),
                        const Expanded(
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
                        _SettingsItemData(
                          icon: Icons.logout_rounded,
                          iconColor: const Color(0xFFE53935),
                          title: 'Sair da conta',
                          subtitle: 'Encerrar sessão no dispositivo',
                          onTap: () => _confirmarLogout(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            AppBottomNavigation(
              currentItem: AppNavigationItem.perfil,
              onInicio: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              ),
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    final currentUser =
        Firebase.apps.isNotEmpty ? FirebaseAuth.instance.currentUser : null;

    if (currentUser == null) {
      return const _ProfileCardContent(
        nome: 'Prof. Ana Paula Santos',
        email: 'ana.santos@escola.edu.br',
        instituicao: 'E.E. Prof. Antônio Lemos',
      );
    }

    return FutureBuilder<Usuario?>(
      future: AuthService().buscarPerfil(currentUser.uid),
      builder: (context, snapshot) {
        final usuario = snapshot.data;
        final nome = usuario?.nome.isNotEmpty == true
            ? usuario!.nome
            : (currentUser.displayName?.isNotEmpty == true
                ? currentUser.displayName!
                : (currentUser.email?.contains('@') == true
                    ? currentUser.email!.split('@').first
                    : 'Professor'));

        final email = usuario?.email.isNotEmpty == true
            ? usuario!.email
            : (currentUser.email ?? '');

        final instituicao = usuario?.instituicao.isNotEmpty == true
            ? usuario!.instituicao
            : 'Instituição de Ensino';

        return _ProfileCardContent(
          nome: nome,
          email: email,
          instituicao: instituicao,
        );
      },
    );
  }
}

class _ProfileCardContent extends StatelessWidget {
  final String nome;
  final String email;
  final String instituicao;

  const _ProfileCardContent({
    required this.nome,
    required this.email,
    required this.instituicao,
  });

  String _obterIniciais(String nomeCompleto) {
    final partes = nomeCompleto.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return 'AP';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

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
      child: Column(
        children: [
          _Avatar(iniciais: _obterIniciais(nome)),
          const SizedBox(height: 10),
          Text(
            nome,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF101827),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF7988A0), fontSize: 11),
          ),
          const SizedBox(height: 7),
          _SchoolBadge(nomeInstituicao: instituicao),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String iniciais;

  const _Avatar({required this.iniciais});

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
      child: Text(
        iniciais,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SchoolBadge extends StatelessWidget {
  final String nomeInstituicao;

  const _SchoolBadge({required this.nomeInstituicao});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        nomeInstituicao,
        style: const TextStyle(
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

class _TurmasStatCard extends StatelessWidget {
  final TurmaService? turmaService;

  const _TurmasStatCard({this.turmaService});

  @override
  Widget build(BuildContext context) {
    final service = turmaService ?? TurmaService();

    return StreamBuilder<List<Turma>>(
      stream: service.monitorarTurmas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const _StatCard(value: '...', label: 'Turmas');
        }

        if (snapshot.hasError) {
          return const _StatCard(value: '-', label: 'Turmas');
        }

        final turmas = snapshot.data ?? [];
        return _StatCard(value: '${turmas.length}', label: 'Turmas');
      },
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
              const Divider(height: 1, indent: 45, color: Color(0xFFF0F2F6)),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: data.iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(data.icon, color: data.iconColor, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle,
                    style:
                        const TextStyle(color: Color(0xFF8A97AA), fontSize: 10),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFB0BAC8),
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

  const _SettingsItemData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
