import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/validadores.dart';

class ResetPasswordScreen extends StatefulWidget {
  final AuthService? authService;

  const ResetPasswordScreen({super.key, this.authService});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const _intervaloReenvio = 60;

  final _emailController = TextEditingController();
  final _codigoController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  late final AuthService _authService;
  Timer? _timerReenvio;

  int _etapa = 0;
  bool _loading = false;
  bool _ocultarSenha = true;
  bool _ocultarConfirmarSenha = true;
  int _segundosParaReenvio = 0;
  String? _codigoValidado;
  String? _emailDaConta;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _timerReenvio?.cancel();
    _emailController.dispose();
    _codigoController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  bool _validarEmail() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _mostrarMensagem('Informe seu e-mail institucional.', isError: true);
      return false;
    }

    final erro = Validadores.email(email);
    if (erro != null) {
      _mostrarMensagem(erro, isError: true);
      return false;
    }

    return true;
  }

  void _iniciarContagemReenvio() {
    _timerReenvio?.cancel();
    setState(() => _segundosParaReenvio = _intervaloReenvio);
    _timerReenvio = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _segundosParaReenvio <= 1) {
        timer.cancel();
        if (mounted) setState(() => _segundosParaReenvio = 0);
        return;
      }
      setState(() => _segundosParaReenvio--);
    });
  }

  void _voltar() {
    if (_loading) return;
    if (_etapa == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      if (_etapa == 2) {
        _codigoValidado = null;
        _emailDaConta = null;
        _senhaController.clear();
        _confirmarSenhaController.clear();
      }
      _etapa--;
    });
  }

  void _mostrarMensagem(String mensagem, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor:
            isError ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _enviarEmailRecuperacao() async {
    FocusScope.of(context).unfocus();

    if (_loading || _segundosParaReenvio > 0 || !_validarEmail()) {
      return;
    }

    setState(() => _loading = true);

    try {
      final email = _emailController.text.trim();
      await _authService.sendPasswordResetEmail(email: email);

      if (mounted) {
        _mostrarMensagem(
          'Se houver uma conta com $email, o e-mail de recuperação chegará em instantes.',
        );
        setState(() => _etapa = 1);
        _iniciarContagemReenvio();
      }
    } catch (e) {
      if (mounted) {
        _mostrarMensagem(e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _validarCodigo() async {
    FocusScope.of(context).unfocus();
    if (_loading) return;

    final erro = Validadores.codigoRedefinicao(_codigoController.text);
    if (erro != null) {
      _mostrarMensagem(erro, isError: true);
      return;
    }

    final codigo =
        Validadores.extrairCodigoRedefinicao(_codigoController.text)!;

    setState(() => _loading = true);

    try {
      final email = await _authService.verificarCodigoRedefinicao(codigo);
      if (mounted) {
        setState(() {
          _codigoValidado = codigo;
          _emailDaConta = email;
          _etapa = 2;
        });
      }
    } catch (e) {
      if (mounted) {
        _mostrarMensagem(e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _redefinirSenha() async {
    FocusScope.of(context).unfocus();
    final codigo = _codigoValidado;
    if (_loading || codigo == null) return;

    final senha = _senhaController.text;
    final erro = Validadores.novaSenha(senha) ??
        Validadores.confirmacaoSenha(senha, _confirmarSenhaController.text);
    if (erro != null) {
      _mostrarMensagem(erro, isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      await _authService.confirmarRedefinicaoSenha(
        codigo: codigo,
        novaSenha: senha,
      );
      if (mounted) {
        _mostrarMensagem('Senha redefinida com sucesso! Entre com a nova senha.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _mostrarMensagem(e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _botaoPrincipal({
    required String rotulo,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF713CEB),
          foregroundColor: Colors.white,
          elevation: 3,
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
            : Text(
                rotulo,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _botaoSecundario(String rotulo, VoidCallback? onPressed) {
    return TextButton(
      onPressed: _loading ? null : onPressed,
      child: Text(
        rotulo,
        style: const TextStyle(
          color: Color(0xFF6438EF),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _toggleSenha(bool ocultar, VoidCallback onToggle) {
    return IconButton(
      onPressed: onToggle,
      icon: Icon(
        ocultar ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: const Color(0xFF91A1B8),
        size: 20,
      ),
    );
  }

  List<Widget> _etapaEmail() {
    return [
      const _FieldLabel('E-MAIL INSTITUCIONAL'),
      const SizedBox(height: 8),
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _enviarEmailRecuperacao(),
        enabled: !_loading,
        decoration: _inputDecoration(hintText: 'seuemail@email.com.br'),
      ),
      const SizedBox(height: 24),
      _botaoPrincipal(
        rotulo: 'Enviar e-mail de recuperação',
        onPressed: _enviarEmailRecuperacao,
      ),
      const SizedBox(height: 12),
      _botaoSecundario(
        'Já recebi o e-mail',
        () => setState(() => _etapa = 1),
      ),
      _botaoSecundario('Voltar para o login', () => Navigator.pop(context)),
    ];
  }

  List<Widget> _etapaCodigo() {
    return [
      const _FieldLabel('LINK OU CÓDIGO DE RECUPERAÇÃO'),
      const SizedBox(height: 8),
      TextField(
        controller: _codigoController,
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _validarCodigo(),
        enabled: !_loading,
        minLines: 1,
        maxLines: 3,
        decoration: _inputDecoration(
          hintText: 'Cole aqui o link recebido por e-mail',
        ),
      ),
      const SizedBox(height: 24),
      _botaoPrincipal(rotulo: 'Validar código', onPressed: _validarCodigo),
      const SizedBox(height: 12),
      _botaoSecundario(
        _segundosParaReenvio > 0
            ? 'Reenviar e-mail em ${_segundosParaReenvio}s'
            : 'Reenviar e-mail',
        _segundosParaReenvio > 0
            ? null
            : () {
                if (_emailController.text.trim().isEmpty) {
                  setState(() => _etapa = 0);
                  return;
                }
                _enviarEmailRecuperacao();
              },
      ),
      _botaoSecundario('Voltar', _voltar),
    ];
  }

  List<Widget> _etapaNovaSenha() {
    return [
      const _FieldLabel('NOVA SENHA'),
      const SizedBox(height: 8),
      TextField(
        controller: _senhaController,
        obscureText: _ocultarSenha,
        textInputAction: TextInputAction.next,
        enabled: !_loading,
        decoration: _inputDecoration(
          hintText: 'Mínimo de 8 caracteres, com letras e números',
          suffixIcon: _toggleSenha(
            _ocultarSenha,
            () => setState(() => _ocultarSenha = !_ocultarSenha),
          ),
        ),
      ),
      const SizedBox(height: 16),
      const _FieldLabel('CONFIRMAR NOVA SENHA'),
      const SizedBox(height: 8),
      TextField(
        controller: _confirmarSenhaController,
        obscureText: _ocultarConfirmarSenha,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _redefinirSenha(),
        enabled: !_loading,
        decoration: _inputDecoration(
          hintText: 'Repita a nova senha',
          suffixIcon: _toggleSenha(
            _ocultarConfirmarSenha,
            () => setState(
              () => _ocultarConfirmarSenha = !_ocultarConfirmarSenha,
            ),
          ),
        ),
      ),
      const SizedBox(height: 24),
      _botaoPrincipal(rotulo: 'Redefinir senha', onPressed: _redefinirSenha),
      const SizedBox(height: 12),
      _botaoSecundario('Voltar', _voltar),
    ];
  }

  String get _titulo {
    switch (_etapa) {
      case 1:
        return 'Verifique seu e-mail';
      case 2:
        return 'Crie uma nova senha';
      default:
        return 'Recuperar acesso';
    }
  }

  String get _descricao {
    switch (_etapa) {
      case 1:
        return 'Abra o e-mail de recuperação e toque no link, ou copie o link '
            'e cole abaixo para continuar por aqui. O link expira em 1 hora.';
      case 2:
        return 'Defina a nova senha da conta ${_emailDaConta ?? ''}.';
      default:
        return 'Informe seu e-mail institucional cadastrado. Enviaremos um '
            'link seguro para você redefinir sua senha.';
    }
  }

  IconData get _icone {
    switch (_etapa) {
      case 1:
        return Icons.mark_email_unread_rounded;
      case 2:
        return Icons.password_rounded;
      default:
        return Icons.lock_reset_rounded;
    }
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
          onPressed: _voltar,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          color: const Color(0xFF111827),
        ),
        title: const Text(
          'Redefinir senha',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE4E9F1)),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5642E8), Color(0xFF7B34ED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F000000),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        _icone,
                        color: Colors.white,
                        size: 35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    _titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _descricao,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_etapa == 0) ..._etapaEmail(),
                  if (_etapa == 1) ..._etapaCodigo(),
                  if (_etapa == 2) ..._etapaNovaSenha(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF58677D),
        letterSpacing: .2,
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String hintText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: Colors.white,
    suffixIcon: suffixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: const BorderSide(color: Color(0xFF713CEB), width: 1.5),
    ),
  );
}