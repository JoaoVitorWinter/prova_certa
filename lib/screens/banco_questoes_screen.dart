import 'dart:async';

import 'package:flutter/material.dart';

import '../models/questao.dart';
import '../services/questao_service.dart';
import 'questao_form_screen.dart';

const dificuldades = ['Fácil', 'Médio', 'Difícil'];

class BancoQuestoesScreen extends StatefulWidget {
  final QuestaoService? questaoService;

  // Quando aberto a partir da criação de prova, permite marcar questões
  // e devolve a lista escolhida com Navigator.pop.
  final bool modoSelecao;
  final List<String> selecionadas;
  final int limite;

  const BancoQuestoesScreen({
    super.key,
    this.questaoService,
    this.modoSelecao = false,
    this.selecionadas = const [],
    this.limite = 20,
  });

  @override
  State<BancoQuestoesScreen> createState() => _BancoQuestoesScreenState();
}

class _BancoQuestoesScreenState extends State<BancoQuestoesScreen> {
  late final QuestaoService questaoService;
  StreamSubscription<List<Questao>>? assinatura;

  List<Questao> questoes = [];
  bool carregando = true;
  Object? erro;

  String dificuldadeFiltro = 'Todas';
  String assuntoFiltro = 'Todos';
  String? questaoAberta;

  final Set<String> selecionadas = {};

  @override
  void initState() {
    super.initState();
    questaoService = widget.questaoService ?? QuestaoService();
    selecionadas.addAll(widget.selecionadas);
    escutarQuestoes();
  }

  @override
  void dispose() {
    assinatura?.cancel();
    super.dispose();
  }

  void escutarQuestoes() {
    assinatura?.cancel();

    assinatura = questaoService.monitorarQuestoes().listen(
      (lista) {
        setState(() {
          questoes = lista;
          carregando = false;

          selecionadas.removeWhere(
            (id) => !lista.any((questao) => questao.id == id),
          );

          if (!assuntos.contains(assuntoFiltro)) {
            assuntoFiltro = 'Todos';
          }
        });
      },
      onError: (Object e) {
        setState(() {
          erro = e;
          carregando = false;
        });
      },
      onDone: () {
        if (mounted && carregando) {
          setState(() => carregando = false);
        }
      },
    );
  }

  List<String> get assuntos {
    final lista = <String>['Todos'];

    for (final questao in questoes) {
      if (!lista.contains(questao.assunto)) {
        lista.add(questao.assunto);
      }
    }

    return lista;
  }

  bool passaNoFiltro(Questao questao) {
    final dificuldadeOk = dificuldadeFiltro == 'Todas' ||
        questao.dificuldade == dificuldadeFiltro;

    final assuntoOk = assuntoFiltro == 'Todos' ||
        questao.assunto == assuntoFiltro;

    return dificuldadeOk && assuntoOk;
  }

  List<Questao> get questoesFiltradas {
    return questoes.where(passaNoFiltro).toList();
  }

  Future<void> abrirFormulario({Questao? questao}) async {
    final salva = await Navigator.push<Questao>(
      context,
      MaterialPageRoute(
        builder: (context) => QuestaoFormScreen(
          questao: questao,
          questaoService: questaoService,
          assuntosExistentes: assuntos.skip(1).toList(),
        ),
      ),
    );

    if (salva == null || !mounted) {
      return;
    }

    setState(() {
      if (!passaNoFiltro(salva)) {
        dificuldadeFiltro = 'Todas';
        assuntoFiltro = 'Todos';
      }

      questaoAberta = salva.id;
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          questao == null
              ? 'Questão criada com sucesso.'
              : 'Questão atualizada com sucesso.',
        ),
      ),
    );
  }

  Future<void> excluirQuestao(Questao questao) async {
    final confirmado = await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: const Text(
            'Excluir questão',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: const Text(
            'Essa questão será removida do banco. Deseja continuar?',
            style: TextStyle(
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),

              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: Color(0xFF64748B),
                ),
              ),
            ),

            TextButton(
              onPressed: () => Navigator.pop(context, true),

              child: const Text(
                'Excluir',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmado != true) {
      return;
    }

    try {
      await questaoService.excluirQuestao(questao.id);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível excluir a questão: $e'),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      questaoAberta = null;
      selecionadas.remove(questao.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Questão excluída.'),
      ),
    );
  }

  void alternarSelecao(Questao questao) {
    if (selecionadas.contains(questao.id)) {
      setState(() => selecionadas.remove(questao.id));
      return;
    }

    if (selecionadas.length >= widget.limite) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pode selecionar no máximo ${widget.limite} questões.',
          ),
        ),
      );
      return;
    }

    setState(() => selecionadas.add(questao.id));
  }

  void adicionarAProva() {
    final resultado = <Questao>[
      for (final id in selecionadas)
        ...questoes.where((questao) => questao.id == id),
    ];

    Navigator.pop(context, resultado);
  }

  Widget buildConteudo() {
    if (carregando) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6545E8),
        ),
      );
    }

    if (erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Color(0xFFE53935),
              ),

              const SizedBox(height: 12),

              const Text(
                'Não foi possível carregar as questões.',

                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                '$erro',
                textAlign: TextAlign.center,

                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  setState(() {
                    carregando = true;
                    erro = null;
                  });

                  escutarQuestoes();
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6545E8),
                  foregroundColor: Colors.white,
                ),

                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (questoes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Icon(
                Icons.quiz_outlined,
                size: 48,
                color: Color(0xFF94A3B8),
              ),

              SizedBox(height: 12),

              Text(
                'Nenhuma questão cadastrada',

                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              SizedBox(height: 6),

              Text(
                'Toque em "+ Adicionar" para criar a primeira questão.',
                textAlign: TextAlign.center,

                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filtradas = questoesFiltradas;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      itemCount: filtradas.length + 1,

      separatorBuilder: (context, index) => const SizedBox(height: 10),

      itemBuilder: (context, index) {
        if (index == 0) {
          final total = filtradas.length;

          final encontradas = Text(
            total == 1
                ? '1 questão encontrada'
                : '$total questões encontradas',

            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
            ),
          );

          if (!widget.modoSelecao) {
            return encontradas;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                '${selecionadas.length} de ${widget.limite} questões selecionadas',

                style: const TextStyle(
                  color: Color(0xFF6545E8),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 4),

              encontradas,
            ],
          );
        }

        final questao = filtradas[index - 1];

        return QuestaoCard(
          questao: questao,
          numero: index,
          aberta: questaoAberta == questao.id,
          selecionada: selecionadas.contains(questao.id),
          onSelecionar:
              widget.modoSelecao ? () => alternarSelecao(questao) : null,

          onToggle: () {
            setState(() {
              questaoAberta = questaoAberta == questao.id ? null : questao.id;
            });
          },

          onEditar: () => abrirFormulario(questao: questao),
          onExcluir: () => excluirQuestao(questao),
        );
      },
    );
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
          'Banco de Questões',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),

            child: TextButton(
              onPressed: () => abrirFormulario(),

              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6545E8),
                backgroundColor: const Color(0xFFEFF2FF),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),

              child: const Text(
                '+ Adicionar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 12),

            decoration: const BoxDecoration(
              color: Colors.white,

              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE5E7EB),
                ),
              ),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),

                  child: Row(
                    children: [
                      for (final nivel in ['Todas', ...dificuldades])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),

                          child: ChipFiltro(
                            rotulo: nivel,
                            ativo: dificuldadeFiltro == nivel,
                            fundo: fundoDificuldade(nivel),
                            texto: textoDificuldade(nivel),

                            onTap: () {
                              setState(() {
                                dificuldadeFiltro = nivel;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),

                  child: Row(
                    children: [
                      for (final assunto in assuntos)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),

                          child: ChipFiltro(
                            rotulo: assunto,
                            ativo: assuntoFiltro == assunto,
                            fundo: const Color(0xFFF1F5F9),
                            texto: const Color(0xFF64748B),
                            fundoAtivo: const Color(0xFF0F172A),

                            onTap: () {
                              setState(() {
                                assuntoFiltro = assunto;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),

          Expanded(
            child: buildConteudo(),
          ),
        ],
      ),

      bottomNavigationBar: widget.modoSelecao
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(14),

                child: ElevatedButton.icon(
                  onPressed: selecionadas.isEmpty ? null : adicionarAProva,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6545E8),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  icon: const Icon(Icons.playlist_add_check),
                  label: Text(
                    'Adicionar à prova (${selecionadas.length})',
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class ChipFiltro extends StatelessWidget {
  final String rotulo;
  final bool ativo;
  final Color fundo;
  final Color texto;
  final Color? fundoAtivo;
  final VoidCallback onTap;

  const ChipFiltro({
    super.key,
    required this.rotulo,
    required this.ativo,
    required this.fundo,
    required this.texto,
    required this.onTap,
    this.fundoAtivo,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),

        decoration: BoxDecoration(
          color: ativo ? (fundoAtivo ?? texto) : fundo,
          borderRadius: BorderRadius.circular(12),
        ),

        child: Text(
          rotulo,

          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ativo ? Colors.white : texto,
          ),
        ),
      ),
    );
  }
}

class QuestaoCard extends StatelessWidget {
  final Questao questao;
  final int numero;
  final bool aberta;
  final bool selecionada;
  final VoidCallback onToggle;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  final VoidCallback? onSelecionar;

  const QuestaoCard({
    super.key,
    required this.questao,
    required this.numero,
    required this.aberta,
    required this.onToggle,
    required this.onEditar,
    required this.onExcluir,
    this.selecionada = false,
    this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: const Color(0xFFF1F5F9),
        ),

        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onToggle,

            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  if (onSelecionar != null) ...[
                    SizedBox(
                      width: 30,
                      height: 30,

                      child: Checkbox(
                        value: selecionada,
                        activeColor: const Color(0xFF6545E8),
                        onChanged: (_) => onSelecionar!(),
                      ),
                    ),

                    const SizedBox(width: 8),
                  ],

                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,

                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Text(
                      '$numero',

                      style: const TextStyle(
                        color: Color(0xFF6545E8),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          aberta ? questao.enunciado : resumo(questao.enunciado),

                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF374151),
                          ),
                        ),

                        const SizedBox(height: 10),

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
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Padding(
                    padding: const EdgeInsets.only(top: 4),

                    child: Icon(
                      aberta
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (aberta) ...[
            const Divider(
              height: 1,
              color: Color(0xFFF1F5F9),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),

              child: Column(
                children: [
                  for (final alternativa in questao.alternativas)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),

                      child: AlternativaItem(
                        letra: alternativa.letra,
                        texto: alternativa.texto,
                        correta: alternativa.letra == questao.correta,
                      ),
                    ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Expanded(
                        child: BotaoAcao(
                          rotulo: 'Editar',
                          fundo: const Color(0xFFEFF2FF),
                          texto: const Color(0xFF6545E8),
                          onTap: onEditar,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: BotaoAcao(
                          rotulo: 'Excluir',
                          fundo: const Color(0xFFFEE2E2),
                          texto: const Color(0xFFEF4444),
                          onTap: onExcluir,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String resumo(String enunciado) {
    if (enunciado.length <= 100) {
      return enunciado;
    }

    return '${enunciado.substring(0, 100)}…';
  }
}

class AlternativaItem extends StatelessWidget {
  final String letra;
  final String texto;
  final bool correta;

  const AlternativaItem({
    super.key,
    required this.letra,
    required this.texto,
    required this.correta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: correta ? const Color(0xFFD1FAE5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),

        border: Border.all(
          color: correta ? const Color(0xFFA7F3D0) : const Color(0xFFF1F5F9),
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,

            decoration: BoxDecoration(
              color: correta ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(8),
            ),

            child: Text(
              letra,

              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: correta ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              texto,

              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color:
                    correta ? const Color(0xFF065F46) : const Color(0xFF374151),
              ),
            ),
          ),

          if (correta) ...[
            const SizedBox(width: 8),

            const Text(
              '✓ Correto',

              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BotaoAcao extends StatelessWidget {
  final String rotulo;
  final Color fundo;
  final Color texto;
  final VoidCallback onTap;

  const BotaoAcao({
    super.key,
    required this.rotulo,
    required this.fundo,
    required this.texto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,

      style: TextButton.styleFrom(
        backgroundColor: fundo,
        foregroundColor: texto,

        padding: const EdgeInsets.symmetric(vertical: 12),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      child: Text(
        rotulo,

        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
        horizontal: 8,
        vertical: 3,
      ),

      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(8),
      ),

      child: Text(
        rotulo,

        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: texto,
        ),
      ),
    );
  }
}

Color fundoDificuldade(String dificuldade) {
  switch (dificuldade) {
    case 'Fácil':
      return const Color(0xFFD1FAE5);

    case 'Médio':
      return const Color(0xFFFEF3C7);

    case 'Difícil':
      return const Color(0xFFFEE2E2);

    default:
      return const Color(0xFFF1F5F9);
  }
}

Color textoDificuldade(String dificuldade) {
  switch (dificuldade) {
    case 'Fácil':
      return const Color(0xFF065F46);

    case 'Médio':
      return const Color(0xFF92400E);

    case 'Difícil':
      return const Color(0xFF991B1B);

    default:
      return const Color(0xFF64748B);
  }
}
