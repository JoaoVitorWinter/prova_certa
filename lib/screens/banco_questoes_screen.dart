
import 'dart:async';

import 'package:flutter/material.dart';
import 'questao_form_screen.dart';
import '../models/questao.dart';
import '../services/questao_service.dart';
import 'questao_form_screen.dart';

const dificuldades = ['Fácil', 'Médio', 'Difícil'];

class BancoQuestoesScreen extends StatefulWidget {
  final QuestaoService? questaoService;
  final List<String> selecionadas;
  final int limite;

  const BancoQuestoesScreen({
    super.key,
    this.questaoService,
    this.selecionadas = const [],
    this.limite = 20,
  });

  @override
  State<BancoQuestoesScreen> createState() =>
      _BancoQuestoesScreenState();
}

class _BancoQuestoesScreenState extends State<BancoQuestoesScreen> {
  late final QuestaoService _service;
  StreamSubscription<List<Questao>>? _subscription;

  List<Questao> _questoes = [];
  final Set<String> _selecionadas = {};

  String _dificuldade = 'Todas';
  String _assunto = 'Todos';
  String? _questaoAberta;

  bool _carregando = true;
  Object? _erro;

  @override
  void initState() {
    super.initState();
    _service = widget.questaoService ?? QuestaoService();
    _selecionadas.addAll(widget.selecionadas);
    _escutarQuestoes();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _escutarQuestoes() {
    _subscription?.cancel();

    setState(() {
      _carregando = true;
      _erro = null;
    });

    _subscription = _service.monitorarQuestoes().listen(
      (questoes) {
        if (!mounted) return;

        setState(() {
          _questoes = questoes;
          _selecionadas.removeWhere(
            (id) => !questoes.any((q) => q.id == id),
          );
          _carregando = false;
          _erro = null;
        });
      },
      onError: (Object erro) {
        if (!mounted) return;

        setState(() {
          _erro = erro;
          _carregando = false;
        });
      },
    );
  }

  List<String> get _assuntos {
    final resultado = <String>{'Todos'};

    for (final questao in _questoes) {
      if (questao.assunto.trim().isNotEmpty) {
        resultado.add(questao.assunto);
      }
    }

    return resultado.toList();
  }

  List<Questao> get _filtradas {
    return _questoes.where((questao) {
      final dificuldadeOk = _dificuldade == 'Todas' ||
          questao.dificuldade == _dificuldade;

      final assuntoOk =
          _assunto == 'Todos' || questao.assunto == _assunto;

      return dificuldadeOk && assuntoOk;
    }).toList();
  }

  void _alternarSelecao(Questao questao) {
    setState(() {
      if (_selecionadas.contains(questao.id)) {
        _selecionadas.remove(questao.id);
        return;
      }

      if (_selecionadas.length >= widget.limite) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pode selecionar no máximo ${widget.limite} questões.',
            ),
          ),
        );
        return;
      }

      _selecionadas.add(questao.id);
    });
  }

  void _adicionarAProva() {
    final resultado = <Questao>[];

    for (final id in _selecionadas) {
      for (final questao in _questoes) {
        if (questao.id == id) {
          resultado.add(questao);
          break;
        }
      }
    }

    Navigator.pop(context, resultado);
  }

  Future<void> _abrirFormulario({Questao? questao}) async {
    final resultado = await Navigator.push<Questao>(
      context,
      MaterialPageRoute(
        builder: (_) => QuestaoFormScreen(questao: questao),
      ),
    );

    if (!mounted || resultado == null) return;

    try {
      if (questao == null) {
        await _service.criarQuestao(resultado);
      } else {
        await _service.atualizarQuestao(resultado);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            questao == null
                ? 'Questão guardada no Firebase.'
                : 'Questão atualizada no Firebase.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível guardar a questão: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _excluirQuestao(Questao questao) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir questão'),
        content: const Text(
          'Deseja realmente excluir esta questão do banco?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _service.excluirQuestao(questao.id);

      if (!mounted) return;

      setState(() {
        _selecionadas.remove(questao.id);
        if (_questaoAberta == questao.id) {
          _questaoAberta = null;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Questão excluída.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível excluir a questão: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final questoes = _filtradas;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF6545E8),
        elevation: 0,
        title: const Text(
          'Banco de Questões',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _abrirFormulario(),
            child: const Text('+ Adicionar'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selecionadas.length} de ${widget.limite} questões selecionadas',
                  style: const TextStyle(
                    color: Color(0xFF6545E8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final nivel in ['Todas', ...dificuldades])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FiltroChip(
                            texto: nivel,
                            ativo: _dificuldade == nivel,
                            onTap: () {
                              setState(() => _dificuldade = nivel);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final assunto in _assuntos)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FiltroChip(
                            texto: assunto,
                            ativo: _assunto == assunto,
                            onTap: () {
                              setState(() => _assunto = assunto);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _erro != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Não foi possível carregar as questões.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$_erro',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _escutarQuestoes,
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : questoes.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhuma questão encontrada no Firebase.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(14),
                            itemCount: questoes.length,
                            itemBuilder: (context, index) {
                              final questao = questoes[index];
                              final selecionada =
                                  _selecionadas.contains(questao.id);
                              final aberta =
                                  _questaoAberta == questao.id;

                              return Card(
                                color: Colors.white,
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  children: [
                                    CheckboxListTile(
                                      value: selecionada,
                                      activeColor: const Color(0xFF6545E8),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      title: Text(
                                        questao.enunciado,
                                        maxLines: aberta ? null : 3,
                                        overflow: aberta
                                            ? TextOverflow.visible
                                            : TextOverflow.ellipsis,
                                      ),
                                      subtitle: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8),
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            _Etiqueta(questao.assunto),
                                            _Etiqueta(questao.dificuldade),
                                          ],
                                        ),
                                      ),
                                      onChanged: (_) =>
                                          _alternarSelecao(questao),
                                    ),
                                    if (aberta)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 12,
                                        ),
                                        child: Column(
                                          children: [
                                            for (final alternativa
                                                in questao.alternativas)
                                              ListTile(
                                                dense: true,
                                                title: Text(
                                                  '${alternativa.letra}. ${alternativa.texto}',
                                                ),
                                                trailing:
                                                    alternativa.letra ==
                                                            questao.correta
                                                        ? const Icon(
                                                            Icons.check_circle,
                                                            color: Colors.green,
                                                          )
                                                        : null,
                                              ),
                                          ],
                                        ),
                                      ),
                                    const Divider(height: 1),
                                    Row(
                                      children: [
                                        TextButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _questaoAberta =
                                                  aberta ? null : questao.id;
                                            });
                                          },
                                          icon: Icon(
                                            aberta
                                                ? Icons.expand_less
                                                : Icons.expand_more,
                                          ),
                                          label: Text(
                                            aberta ? 'Recolher' : 'Ver questão',
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          tooltip: 'Editar',
                                          onPressed: () =>
                                              _abrirFormulario(
                                            questao: questao,
                                          ),
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                        IconButton(
                                          tooltip: 'Excluir',
                                          onPressed: () =>
                                              _excluirQuestao(questao),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: ElevatedButton.icon(
            onPressed: _selecionadas.isEmpty ? null : _adicionarAProva,
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
              'Adicionar à prova (${_selecionadas.length})',
            ),
          ),
        ),
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String texto;
  final bool ativo;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.texto,
    required this.ativo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(texto),
      onPressed: onTap,
      backgroundColor:
          ativo ? const Color(0xFF6545E8) : const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        color: ativo ? Colors.white : const Color(0xFF64748B),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;

  const _Etiqueta(this.texto);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: Color(0xFF3730A3),
          fontSize: 11,
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
          color: texto,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}