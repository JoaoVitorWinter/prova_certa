import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final AuthService? authService;

  const RegisterScreen({super.key, this.authService});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _instituicaoController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  late final AuthService _authService;

  bool _loading = false;
  bool _ocultarSenha = true;
  bool _ocultarConfirmarSenha = true;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _instituicaoController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  bool _validarFormulario() {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final instituicao = _instituicaoController.text.trim();
    final senha = _senhaController.text;
    final confirmarSenha = _confirmarSenhaController.text;

    if (nome.isEmpty) return _erro('Informe o nome completo.');
    if (email.isEmpty) return _erro('Informe o e-mail institucional.');
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email)) {
      return _erro('Informe um formato de e-mail válido.');
    }
    if (instituicao.isEmpty) return _erro('Informe a instituição de ensino.');
    if (senha.isEmpty) return _erro('Informe a senha de acesso.');
    if (senha.length < 6) {
      return _erro('A senha deve ter pelo menos 6 caracteres.');
    }
    if (confirmarSenha.isEmpty) return _erro('Confirme a senha de acesso.');
    if (senha != confirmarSenha) {
      return _erro('As senhas informadas não coincidem.');
    }
    return true;
  }

  bool _erro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return false;
  }

  void _voltarParaLogin() {
    if (_loading) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(authService: widget.authService),
      ),
    );
  }

  Future<void> _criarConta() async {
    FocusScope.of(context).unfocus();
    if (_loading || !_validarFormulario()) return;

    setState(() => _loading = true);
    try {
      await _authService.cadastrarProfessor(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        instituicao: _instituicaoController.text.trim(),
        password: _senhaController.text,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(authService: widget.authService),
          ),
        );
      }
    } catch (e) {
      if (mounted) _erro(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildCampo({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    Widget? suffixIcon,
    ValueChanged<String>? onSubmitted,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF58677D),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            obscureText: obscureText,
            onSubmitted: onSubmitted,
            enabled: !_loading,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 17,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: const BorderSide(
                  color: Color(0xFF713CEB),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSenha(bool ocultar, VoidCallback onToggle) {
    return IconButton(
      onPressed: onToggle,
      icon: Icon(
        ocultar ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: const Color(0xFF91A1B8),
        size: 20,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: _loading ? null : _voltarParaLogin,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          color: const Color(0xFF111827),
        ),
        title: const Text(
          'Criar conta',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCampo(
                    label: 'NOME COMPLETO',
                    hint: 'Seu nome completo',
                    controller: _nomeController,
                    keyboardType: TextInputType.name,
                  ),
                  _buildCampo(
                    label: 'E-MAIL INSTITUCIONAL',
                    hint: 'seuemail@email.com.br',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _buildCampo(
                    label: 'INSTITUIÇÃO DE ENSINO',
                    hint: 'Nome da escola ou instituição',
                    controller: _instituicaoController,
                  ),
                  _buildCampo(
                    label: 'SENHA',
                    hint: 'Mínimo de 6 caracteres',
                    controller: _senhaController,
                    obscureText: _ocultarSenha,
                    suffixIcon: _buildToggleSenha(
                      _ocultarSenha,
                      () => setState(() => _ocultarSenha = !_ocultarSenha),
                    ),
                  ),
                  _buildCampo(
                    label: 'CONFIRMAR SENHA',
                    hint: 'Repita a senha',
                    controller: _confirmarSenhaController,
                    obscureText: _ocultarConfirmarSenha,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _criarConta(),
                    suffixIcon: _buildToggleSenha(
                      _ocultarConfirmarSenha,
                      () => setState(
                        () => _ocultarConfirmarSenha = !_ocultarConfirmarSenha,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _criarConta,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF713CEB),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        disabledBackgroundColor:
                            const Color(0xFF713CEB).withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Criar conta',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loading ? null : _voltarParaLogin,
                    child: const Text(
                      'Já possui uma conta? Entrar',
                      style: TextStyle(
                        color: Color(0xFF6438EF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
