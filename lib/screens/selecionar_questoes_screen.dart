
import 'package:flutter/material.dart';

import '../models/questao.dart';
import '../services/questao_service.dart';

class SelecionarQuestoesScreen extends StatefulWidget {
  final int limite;
  final List<String> selecionadas;
  final QuestaoService? questaoService;

  const SelecionarQuestoesScreen({
    super.key,
    this.limite = 10,
    this.selecionadas = const [],
    this.questaoService,
  });

  @override
  State<SelecionarQuestoesScreen> createState() =>
      _SelecionarQuestoesScreenState();
}

class _SelecionarQuestoesScreenState
    extends State<SelecionarQuestoesScreen> {
  late final QuestaoService _questaoService;
  late final List<String> _selecionadas;

  @override
  void initState() {
    super.initState();

    _questaoService = widget.questaoService ?? QuestaoService();
    _selecionadas = [...widget.selecionadas];
  }

  bool get _limiteAtingido {
    return _selecionadas.length >= widget.limite;
  }

  void _alternarSelecao(Questao questao) {
    if (_selecionadas.contains(questao.id)) {
      setState(() {
        _selecionadas.remove(questao.id);
      });
      return;
    }

    if (_limiteAtingido) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Limite de ${widget.limite} questões atingido.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _selecionadas.add(questao.id);
    });
  }

  void _confirmar(List<Questao> questoes) {
    final escolhidas = questoes
        .where((questao) => _selecionadas.contains(questao.id))
        .toList();

    Navigator.pop<List<Questao>>(context, escolhidas);
  }

  void _limparSelecao() {
    setState(() {
      _selecionadas.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xFF6545E8),
        ),
        title: const Text(
          'Selecionar questões',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<Questao>>(
        stream: _questaoService.monitorarQuestoes(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _mensagemEstado(
              icone: Icons.error_outline,
              titulo: 'Não foi possível carregar as questões',
              descricao:
                  'Verifica a ligação ao Firebase e se tens sessão iniciada.',
              acao: 'Voltar',
              aoClicar: () => Navigator.pop(context),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6545E8),
              ),
            );
          }

          final questoes = snapshot.data ?? <Questao>[];

          if (questoes.isEmpty) {
            return _mensagemEstado(
              icone: Icons.menu_book_outlined,
              titulo: 'Ainda não existem questões',
              descricao:
                  'Adiciona questões ao banco para poderes seleccioná-las.',
              acao: 'Voltar',
              aoClicar: () => Navigator.pop(context),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  itemCount: questoes.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Text(
                        'BANCO DE QUESTÕES — SELECCIONE ATÉ '
                        '${widget.limite}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: Color(0xFF64748B),
                        ),
                      );
                    }

                    final questao = questoes[index - 1];

                    return QuestaoSelecionavel(
                      questao: questao,
                      selecionada:
                          _selecionadas.contains(questao.id),
                      onTap: () => _alternarSelecao(questao),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: Color(0xFFE5E7EB),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_selecionadas.length} de '
                              '${widget.limite} questões seleccionadas',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          if (_selecionadas.isNotEmpty)
                            TextButton(
                              onPressed: _limparSelecao,
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    const Color(0xFF6545E8),
                              ),
                              child: const Text('Limpar'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      BotaoGradiente(
                        rotulo: 'Confirmar selecção',
                        habilitado: _selecionadas.isNotEmpty,
                        onTap: () => _confirmar(questoes),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _mensagemEstado({
    required IconData icone,
    required String titulo,
    required String descricao,
    required String acao,
    required VoidCallback aoClicar,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icone,
              size: 54,
              color: const Color(0xFF6545E8),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              descricao,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: aoClicar,
              child: Text(acao),
            ),
          ],
        ),
      ),
    );
  }
}

class QuestaoSelecionavel extends StatelessWidget {
  final Questao questao;
  final bool selecionada;
  final VoidCallback onTap;

  const QuestaoSelecionavel({
    super.key,
    required this.questao,
    required this.selecionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selecionada
              ? const Color(0xFFEFF2FF)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selecionada
                ? const Color(0xFF6545E8)
                : const Color(0xFFF1F5F9),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selecionada
                    ? const Color(0xFF6545E8)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: selecionada
                      ? const Color(0xFF6545E8)
                      : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: selecionada
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _resumo(questao.enunciado),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      TagQuestao(
                        rotulo: questao.assunto,
                        fundo: const Color(0xFFE0E7FF),
                        texto: const Color(0xFF3730A3),
                      ),
                      TagQuestao(
                        rotulo: questao.dificuldade,
                        fundo: _fundoDificuldade(
                          questao.dificuldade,
                        ),
                        texto: _textoDificuldade(
                          questao.dificuldade,
                        ),
                      ),
                      TagQuestao(
                        rotulo: 'Gabarito: ${questao.correta}',
                        fundo: const Color(0xFFF0FDF4),
                        texto: const Color(0xFF15803D),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resumo(String enunciado) {
    if (enunciado.length <= 90) {
      return enunciado;
    }

    return '${enunciado.substring(0, 90)}…';
  }

  Color _fundoDificuldade(String dificuldade) {
    switch (dificuldade.toLowerCase()) {
      case 'fácil':
      case 'facil':
        return const Color(0xFFDCFCE7);
      case 'difícil':
      case 'dificil':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFFEF3C7);
    }
  }

  Color _textoDificuldade(String dificuldade) {
    switch (dificuldade.toLowerCase()) {
      case 'fácil':
      case 'facil':
        return const Color(0xFF166534);
      case 'difícil':
      case 'dificil':
        return const Color(0xFF991B1B);
      default:
        return const Color(0xFF92400E);
    }
  }
}

class TagQuestao extends StatelessWidget {
  final String rotulo;
  final Color fundo;
  final Color texto;

  const TagQuestao({
    super.key,
    required this.rotulo,
    required this.fundo,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        rotulo,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: texto,
        ),
      ),
    );
  }
}

class BotaoGradiente extends StatelessWidget {
  final String rotulo;
  final bool habilitado;
  final VoidCallback onTap;

  const BotaoGradiente({
    super.key,
    required this.rotulo,
    required this.habilitado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: habilitado
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6545E8),
                  Color(0xFF7C3AED),
                ],
              )
            : null,
        color: habilitado
            ? null
            : const Color(0xFFD8D4F8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: habilitado ? onTap : null,
          child: Center(
            child: Text(
              rotulo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
