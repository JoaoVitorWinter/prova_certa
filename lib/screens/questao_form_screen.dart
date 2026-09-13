import 'package:flutter/material.dart';

import '../mocks/questoes_mock.dart';
import '../models/alternativa.dart';
import '../models/questao.dart';
import 'banco_questoes_screen.dart';

const disciplinaPadrao = 'Biologia';
const maximoAlternativas = 5;
const minimoAlternativas = 2;

class QuestaoFormScreen extends StatefulWidget {
  final Questao? questao;

  const QuestaoFormScreen({
    super.key,
    this.questao,
  });

  @override
  State<QuestaoFormScreen> createState() => _QuestaoFormScreenState();
}

class _QuestaoFormScreenState extends State<QuestaoFormScreen> {
  final enunciadoController = TextEditingController();
  final assuntoController = TextEditingController();

  final List<TextEditingController> alternativaControllers = [];

  String dificuldade = 'Fácil';
  int corretaIndex = 0;

  bool get editando => widget.questao != null;

  @override
  void initState() {
    super.initState();

    final questao = widget.questao;

    if (questao == null) {
      for (var i = 0; i < maximoAlternativas; i++) {
        alternativaControllers.add(TextEditingController());
      }

      return;
    }

    enunciadoController.text = questao.enunciado;
    assuntoController.text = questao.assunto;
    dificuldade = questao.dificuldade;

    for (final alternativa in questao.alternativas) {
      alternativaControllers.add(
        TextEditingController(text: alternativa.texto),
      );
    }

    final indice = questao.alternativas.indexWhere(
      (alternativa) => alternativa.letra == questao.correta,
    );

    corretaIndex = indice == -1 ? 0 : indice;
  }

  @override
  void dispose() {
    enunciadoController.dispose();
    assuntoController.dispose();

    for (final controller in alternativaControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  String letraPara(int index) {
    return String.fromCharCode(65 + index);
  }

  List<String> get assuntosExistentes {
    final lista = <String>[];

    for (final questao in questoesMock) {
      if (!lista.contains(questao.assunto)) {
        lista.add(questao.assunto);
      }
    }

    return lista;
  }

  bool get alternativasPreenchidas {
    return alternativaControllers.every(
      (controller) => controller.text.trim().isNotEmpty,
    );
  }

  bool get formularioValido {
    return enunciadoController.text.trim().isNotEmpty &&
        assuntoController.text.trim().isNotEmpty &&
        alternativaControllers.length >= minimoAlternativas &&
        alternativasPreenchidas;
  }

  void adicionarAlternativa() {
    if (alternativaControllers.length >= maximoAlternativas) {
      return;
    }

    setState(() {
      alternativaControllers.add(TextEditingController());
    });
  }

  void removerAlternativa(int index) {
    if (alternativaControllers.length <= minimoAlternativas) {
      return;
    }

    setState(() {
      alternativaControllers.removeAt(index).dispose();

      if (corretaIndex == index) {
        corretaIndex = 0;
      } else if (corretaIndex > index) {
        corretaIndex = corretaIndex - 1;
      }
    });
  }

  void salvar() {
    if (!formularioValido) {
      return;
    }

    final alternativas = <Alternativa>[];

    for (var i = 0; i < alternativaControllers.length; i++) {
      alternativas.add(
        Alternativa(
          letra: letraPara(i),
          texto: alternativaControllers[i].text.trim(),
        ),
      );
    }

    final questao = Questao(
      id: widget.questao?.id ??
          'q${DateTime.now().millisecondsSinceEpoch}',
      enunciado: enunciadoController.text.trim(),
      alternativas: alternativas,
      correta: letraPara(corretaIndex),
      assunto: assuntoController.text.trim(),
      dificuldade: dificuldade,
      disciplina: widget.questao?.disciplina ?? disciplinaPadrao,
    );

    Navigator.pop(context, questao);
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

        title: Text(
          editando ? 'Editar questão' : 'Nova questão',

          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          Container(
            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),

              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const RotuloCampo('Enunciado'),

                TextField(
                  controller: enunciadoController,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,

                  decoration: campoDecoration(
                    'Digite o enunciado da questão',
                  ),

                  onChanged: (valor) {
                    setState(() {});
                  },
                ),

                const SizedBox(height: 18),

                const RotuloCampo('Assunto'),

                TextField(
                  controller: assuntoController,
                  textCapitalization: TextCapitalization.sentences,

                  decoration: campoDecoration('Ex: Citologia'),

                  onChanged: (valor) {
                    setState(() {});
                  },
                ),

                if (assuntosExistentes.isNotEmpty) ...[
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,

                    children: [
                      for (final assunto in assuntosExistentes)
                        ChipFiltro(
                          rotulo: assunto,
                          ativo: assuntoController.text.trim() == assunto,
                          fundo: const Color(0xFFF1F5F9),
                          texto: const Color(0xFF64748B),
                          fundoAtivo: const Color(0xFF0F172A),

                          onTap: () {
                            setState(() {
                              assuntoController.text = assunto;
                            });
                          },
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 18),

                const RotuloCampo('Dificuldade'),

                Row(
                  children: [
                    for (final nivel in dificuldades)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: nivel == dificuldades.last ? 0 : 8,
                          ),

                          child: BotaoDificuldade(
                            rotulo: nivel,
                            ativo: dificuldade == nivel,

                            onTap: () {
                              setState(() {
                                dificuldade = nivel;
                              });
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),

              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Alternativas',

                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Toque na letra para marcar a alternativa correta.',

                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                ),

                const SizedBox(height: 16),

                for (var i = 0; i < alternativaControllers.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),

                    child: CampoAlternativa(
                      letra: letraPara(i),
                      controller: alternativaControllers[i],
                      correta: corretaIndex == i,

                      podeRemover:
                          alternativaControllers.length > minimoAlternativas,

                      onMarcarCorreta: () {
                        setState(() {
                          corretaIndex = i;
                        });
                      },

                      onRemover: () => removerAlternativa(i),

                      onChanged: (valor) {
                        setState(() {});
                      },
                    ),
                  ),

                if (alternativaControllers.length < maximoAlternativas)
                  TextButton.icon(
                    onPressed: adicionarAlternativa,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Adicionar alternativa'),

                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6545E8),
                      backgroundColor: const Color(0xFFEFF2FF),

                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (!formularioValido)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),

              child: Container(
                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                ),

                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Color(0xFF92400E),
                    ),

                    SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'Preencha o enunciado, o assunto e todas as '
                        'alternativas para salvar.',

                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          SizedBox(
            height: 54,

            child: ElevatedButton(
              onPressed: formularioValido ? salvar : null,

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6545E8),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFD8D4F8),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),

              child: Text(
                editando ? 'Salvar alterações' : 'Criar questão',

                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class RotuloCampo extends StatelessWidget {
  final String texto;

  const RotuloCampo(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),

      child: Text(
        texto.toUpperCase(),

        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}

class BotaoDificuldade extends StatelessWidget {
  final String rotulo;
  final bool ativo;
  final VoidCallback onTap;

  const BotaoDificuldade({
    super.key,
    required this.rotulo,
    required this.ativo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,

      child: Container(
        height: 44,
        alignment: Alignment.center,

        decoration: BoxDecoration(
          color: ativo ? textoDificuldade(rotulo) : fundoDificuldade(rotulo),
          borderRadius: BorderRadius.circular(12),
        ),

        child: Text(
          rotulo,

          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: ativo ? Colors.white : textoDificuldade(rotulo),
          ),
        ),
      ),
    );
  }
}

class CampoAlternativa extends StatelessWidget {
  final String letra;
  final TextEditingController controller;
  final bool correta;
  final bool podeRemover;
  final VoidCallback onMarcarCorreta;
  final VoidCallback onRemover;
  final ValueChanged<String> onChanged;

  const CampoAlternativa({
    super.key,
    required this.letra,
    required this.controller,
    required this.correta,
    required this.podeRemover,
    required this.onMarcarCorreta,
    required this.onRemover,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),

          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onMarcarCorreta,

            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,

              decoration: BoxDecoration(
                color: correta
                    ? const Color(0xFF10B981)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),

              child: Text(
                letra,

                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: correta ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
            onChanged: onChanged,

            decoration: campoDecoration(
              'Texto da alternativa $letra',
            ).copyWith(
              fillColor: correta
                  ? const Color(0xFFD1FAE5)
                  : const Color(0xFFF8FAFC),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),

                borderSide: BorderSide(
                  color: correta
                      ? const Color(0xFFA7F3D0)
                      : const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),

        if (podeRemover)
          IconButton(
            onPressed: onRemover,
            tooltip: 'Remover alternativa',

            icon: const Icon(
              Icons.close,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
          ),
      ],
    );
  }
}

InputDecoration campoDecoration(String? hint) {
  return InputDecoration(
    hintText: hint,

    hintStyle: const TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 14,
    ),

    filled: true,
    fillColor: const Color(0xFFF8FAFC),

    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),

    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),

      borderSide: const BorderSide(
        color: Color(0xFFE5E7EB),
        width: 1.5,
      ),
    ),

    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),

      borderSide: const BorderSide(
        color: Color(0xFFE5E7EB),
        width: 1.5,
      ),
    ),

    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),

      borderSide: const BorderSide(
        color: Color(0xFF6545E8),
        width: 1.5,
      ),
    ),
  );
}
