import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../utils/validadores.dart';

class EditProfileScreen extends StatefulWidget {
  final AuthService? authService;
  final Usuario? usuarioAtual;

  const EditProfileScreen({
    super.key,
    this.authService,
    this.usuarioAtual,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final AuthService _authService;
  late final TextEditingController _nomeController;
  late final TextEditingController _emailController;
  late final TextEditingController _escolaController;
  bool _salvando = false;

  String _obterIniciais(String nomeCompleto) {
    final partes = nomeCompleto
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return 'P';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();

    final usuario = widget.usuarioAtual;
    final currentUser =
        Firebase.apps.isNotEmpty ? _authService.currentUser : null;

    final nomeInicial = usuario?.nome.isNotEmpty == true
        ? usuario!.nome
        : (currentUser?.displayName?.isNotEmpty == true
            ? currentUser!.displayName!
            : (currentUser?.email?.contains('@') == true
                ? currentUser!.email!.split('@').first
                : ''));

    final emailInicial = usuario?.email.isNotEmpty == true
        ? usuario!.email
        : (currentUser?.email ?? '');

    final escolaInicial = usuario?.instituicao.isNotEmpty == true
        ? usuario!.instituicao
        : '';

    _nomeController = TextEditingController(text: nomeInicial);
    _emailController = TextEditingController(text: emailInicial);
    _escolaController = TextEditingController(text: escolaInicial);

    _nomeController.addListener(() => setState(() {}));

    if (usuario == null && currentUser != null) {
      _carregarPerfil(currentUser.uid);
    }
  }

  Future<void> _carregarPerfil(String uid) async {
    final perfil = await _authService.buscarPerfil(uid);
    if (perfil != null && mounted) {
      setState(() {
        if (_nomeController.text.isEmpty && perfil.nome.isNotEmpty) {
          _nomeController.text = perfil.nome;
        }
        if (_emailController.text.isEmpty && perfil.email.isNotEmpty) {
          _emailController.text = perfil.email;
        }
        if (_escolaController.text.isEmpty && perfil.instituicao.isNotEmpty) {
          _escolaController.text = perfil.instituicao;
        }
      });
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _escolaController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    FocusScope.of(context).unfocus();

    final nome = _nomeController.text.trim();
    final erro = Validadores.nomeCompleto(nome) ??
        Validadores.instituicao(_escolaController.text, obrigatoria: false);
    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(erro),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final uid = widget.usuarioAtual?.id ?? _authService.currentUserId;

    if (uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alterações salvas.'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
      return;
    }

    setState(() => _salvando = true);

    try {
      await _authService.atualizarPerfil(
        uid: uid,
        nome: nome,
        instituicao: _escolaController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso.'),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar perfil: $e'),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _settingsAppBar(context, 'Editar perfil'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(23, 20, 23, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5D48F2), Color(0xFF7B2EEB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      _obterIniciais(_nomeController.text),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -5,
                    bottom: -5,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE7EAF0)),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Color(0xFF6542ED),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _ProfileField(
              label: 'NOME COMPLETO',
              controller: _nomeController,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 17),
            _ProfileField(
              label: 'E-MAIL INSTITUCIONAL',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              readOnly: true,
              helperText: 'O e-mail é vinculado à sua conta de acesso.',
            ),
            const SizedBox(height: 17),
            _ProfileField(
              label: 'ESCOLA / INSTITUIÇÃO',
              controller: _escolaController,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF713CEB),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _salvando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Salvar alterações',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool readOnly;
  final String? helperText;

  const _ProfileField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.textInputAction,
    this.readOnly = false,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF58677D),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: .2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          readOnly: readOnly,
          decoration: _fieldDecoration().copyWith(
            helperText: helperText,
            helperStyle: const TextStyle(
              color: Color(0xFF8E9BAE),
              fontSize: 11,
            ),
            fillColor: readOnly ? const Color(0xFFF8FAFC) : Colors.white,
          ),
        ),
      ],
    );
  }
}

InputDecoration _fieldDecoration() {
  return InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Color(0xFF713CEB), width: 1.5),
    ),
  );
}

PreferredSizeWidget _settingsAppBar(BuildContext context, String title) {
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
    title: Text(
      title,
      style: const TextStyle(
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
