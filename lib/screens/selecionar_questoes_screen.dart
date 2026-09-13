import 'package:flutter/material.dart';

import '../mocks/questoes_mock.dart';
import '../models/questao.dart';
import 'banco_questoes_screen.dart';

class SelecionarQuestoesScreen extends StatefulWidget {
  final int limite;
  final List<String> selecionadas;

  const SelecionarQuestoesScreen({
    super.key,
    this.limite = 10,
    this.selecionadas = const [],
  });

  @override
  State<SelecionarQuestoesScreen> createState() =>
      _SelecionarQuestoesScreenState();
}

class _SelecionarQuestoesScreenState extends State<SelecionarQuestoesScreen> {
  late final List<String> selecionadas;

  @override
  void initState() {
    super.initState();

    selecionadas = [...widget.selecionadas];
  }

  bool get limiteAtingido {
    return selecionadas.length >= widget.limite;
  }

  void alternarSelecao(Questao questao) {
    if (selecionadas.contains(questao.id)) {
      setState(() {
        selecionadas.remove(questao.id);
      });

      return;
    }

    if (limiteAtingido) {
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
      selecionadas.add(questao.id);
    });
  }

  void confirmar() {
    final escolhidas = questoesMock
        .where((questao) => selecionadas.contains(questao.id))
        .toList();

    Navigator.pop(context, escolhidas);
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

      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              itemCount: questoesMock.length + 1,

              separatorBuilder: (context, index) => const SizedBox(height: 10),

              itemBuilder: (context, index) {
                if (index == 0) {
                  return Text(
                    'BANCO DE QUESTÕES — SELECIONE ATÉ ${widget.limite}',

                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: Color(0xFF64748B),
                    ),
                  );
                }

                final questao = questoesMock[index - 1];

                return QuestaoSelecionavel(
                  questao: questao,
                  selecionada: selecionadas.contains(questao.id),
                  onTap: () => alternarSelecao(questao),
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
                          '${selecionadas.length} de ${widget.limite} '
                          'questões selecionadas',

                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),

                      if (selecionadas.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selecionadas.clear();
                            });
                          },

                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF94A3B8),
                          ),

                          child: const Text('Limpar'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  BotaoGradiente(
                    rotulo: 'Confirmar seleção',
                    habilitado: selecionadas.isNotEmpty,
                    onTap: confirmar,
                  ),
                ],
              ),
            ),
          ),
        ],
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
          color: selecionada ? const Color(0xFFEFF2FF) : Colors.white,
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
                    resumo(questao.enunciado),

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
                        fundo: fundoDificuldade(questao.dificuldade),
                        texto: textoDificuldade(questao.dificuldade),
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

  String resumo(String enunciado) {
    if (enunciado.length <= 90) {
      return enunciado;
    }

    return '${enunciado.substring(0, 90)}…';
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

        color: habilitado ? null : const Color(0xFFD8D4F8),
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
