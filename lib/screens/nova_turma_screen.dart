import 'package:flutter/material.dart';

import '../models/turma.dart';
import '../services/turma_service.dart';

class NovaTurmaScreen extends StatefulWidget {
  final Turma? turmaParaEditar;
  final TurmaService? turmaService;

  const NovaTurmaScreen({
    super.key,
    this.turmaParaEditar,
    this.turmaService,
  });

  @override
  State<NovaTurmaScreen> createState() => _NovaTurmaScreenState();
}

class _NovaTurmaScreenState extends State<NovaTurmaScreen> {
  late final TextEditingController _nomeController;
  late final TextEditingController _anoController;
  late final TextEditingController _disciplinaController;
  late String _periodo;
  late final TurmaService _turmaService;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _turmaService = widget.turmaService ?? TurmaService();
    final turma = widget.turmaParaEditar;
    _nomeController = TextEditingController(text: turma?.nome ?? '');
    _anoController = TextEditingController(text: turma?.ano ?? '');
    _disciplinaController =
        TextEditingController(text: turma?.disciplina ?? '');
    _periodo =
        (turma != null && turma.periodo.isNotEmpty) ? turma.periodo : 'Manhã';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _anoController.dispose();
    _disciplinaController.dispose();
    super.dispose();
  }

  bool get _formularioPreenchido {
    return _nomeController.text.trim().isNotEmpty &&
        _anoController.text.trim().isNotEmpty &&
        _disciplinaController.text.trim().isNotEmpty;
  }

  Future<void> _salvarTurma() async {
    FocusScope.of(context).unfocus();
    if (!_formularioPreenchido || _loading) return;

    setState(() => _loading = true);

    try {
      if (widget.turmaParaEditar != null) {
        await _turmaService.atualizarTurma(
          turmaId: widget.turmaParaEditar!.id,
          nome: _nomeController.text.trim(),
          ano: _anoController.text.trim(),
          disciplina: _disciplinaController.text.trim(),
          periodo: _periodo,
        );
      } else {
        await _turmaService.criarTurma(
          nome: _nomeController.text.trim(),
          ano: _anoController.text.trim(),
          disciplina: _disciplinaController.text.trim(),
          periodo: _periodo,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final mensagem = e
            .toString()
            .replaceFirst('Exception: ', '')
            .replaceFirst('ArgumentError: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagem),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ehEdicao = widget.turmaParaEditar != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xFF6545E8),
        ),
        title: Text(
          ehEdicao ? 'Editar turma' : 'Nova turma',
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            ehEdicao ? 'Dados da turma' : 'Informações da turma',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ehEdicao
                ? 'Atualize os dados da turma selecionada.'
                : 'Preencha os dados para criar uma nova turma.',
            style: const TextStyle(
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Turma',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nomeController,
                  enabled: !_loading,
                  decoration: campoDecoration('Ex: 1º A'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Ano',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _anoController,
                  enabled: !_loading,
                  decoration: campoDecoration('Ex: 1º Ano'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Disciplina',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _disciplinaController,
                  enabled: !_loading,
                  decoration: campoDecoration('Ex: Matemática'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Turno',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _periodo,
                  decoration: campoDecoration(null),
                  items: const [
                    DropdownMenuItem(
                      value: 'Manhã',
                      child: Text('Manhã'),
                    ),
                    DropdownMenuItem(
                      value: 'Tarde',
                      child: Text('Tarde'),
                    ),
                    DropdownMenuItem(
                      value: 'Noite',
                      child: Text('Noite'),
                    ),
                  ],
                  onChanged: _loading
                      ? null
                      : (valor) {
                          if (valor == null) return;
                          setState(() {
                            _periodo = valor;
                          });
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed:
                  (_formularioPreenchido && !_loading) ? _salvarTurma : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6545E8),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFD8D4F8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
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
                      ehEdicao ? 'Salvar alterações' : 'Criar turma',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration campoDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF6545E8),
          width: 1.5,
        ),
      ),
    );
  }
}