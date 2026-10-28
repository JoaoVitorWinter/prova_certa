import 'dart:async';

import 'package:flutter/material.dart';

import '../models/prova.dart';
import '../models/questao.dart';
import '../models/turma.dart';
import '../services/prova_service.dart';
import '../services/questao_service.dart';
import '../services/turma_service.dart';
import 'banco_questoes_screen.dart';
import 'provas_screen.dart';

class NovaProvaScreen extends StatefulWidget {
  final ProvaService? provaService;
  final TurmaService? turmaService;
  final QuestaoService? questaoService;

  const NovaProvaScreen({
    super.key,
    this.provaService,
    this.turmaService,
    this.questaoService,
  });

  @override
  State<NovaProvaScreen> createState() => _NovaProvaScreenState();
}

class _NovaProvaScreenState extends State<NovaProvaScreen> {
  late final ProvaService _provaService;
  late final TurmaService _turmaService;
  late final QuestaoService _questaoService;
  StreamSubscription<List<Turma>>? _turmasSub;
  StreamSubscription<List<Questao>>? _questoesSub;

  List<Questao> _questoesDisponiveis = [];
  bool _carregandoQuestoes = true;
  Object? _erroQuestoes;

  int _etapa = 0;
  String _nome = '';
  List<Turma> _turmas = [];
  bool _carregandoTurmas = true;
  Turma? _turma;
  DateTime _dataAplicacao = DateUtils.dateOnly(DateTime.now());
  int _quantidadeQuestoes = 10;
  bool _embaralharQuestoes = false;
  bool _embaralharAlternativas = false;
  int _numeroVersoes = 1;
  final List<String> _questoesSelecionadas = [];
  bool _salvando = false;

  List<Questao> get _questoesEscolhidas => [
    for (final id in _questoesSelecionadas)
      ..._questoesDisponiveis.where((questao) => questao.id == id),
  ];

  bool get _etapaValida {
    switch (_etapa) {
      case 0:
        return _nome.trim().isNotEmpty && _turma != null;
      case 1:
        return _questoesSelecionadas.isNotEmpty;
      default:
        return _nome.trim().isNotEmpty &&
            _turma != null &&
            _questoesSelecionadas.isNotEmpty;
    }
  }

  @override
  void initState() {
    super.initState();
    _provaService = widget.provaService ?? ProvaService();
    _turmaService = widget.turmaService ?? TurmaService();
    _turmasSub = _turmaService.monitorarTurmas().listen(
      (turmas) {
        setState(() {
          _turmas = turmas;
          _carregandoTurmas = false;
          if (_turma != null && !turmas.any((t) => t.id == _turma!.id)) {
            _turma = null;
          }
        });
      },
      onError: (Object _) {
        setState(() => _carregandoTurmas = false);
      },
      onDone: () {
        if (mounted && _carregandoTurmas) {
          setState(() => _carregandoTurmas = false);
        }
      },
    );
    _questaoService = widget.questaoService ?? QuestaoService();
    _escutarQuestoes();
  }

  @override
  void dispose() {
    _turmasSub?.cancel();
    _questoesSub?.cancel();
    super.dispose();
  }

  void _escutarQuestoes() {
    _questoesSub?.cancel();
    _questoesSub = _questaoService.monitorarQuestoes().listen(
      (questoes) {
        setState(() {
          _questoesDisponiveis = questoes;
          _carregandoQuestoes = false;
          _erroQuestoes = null;
          _questoesSelecionadas.removeWhere(
            (id) => !questoes.any((questao) => questao.id == id),
          );
        });
      },
      onError: (Object e) {
        setState(() {
          _erroQuestoes = e;
          _carregandoQuestoes = false;
        });
      },
      onDone: () {
        if (mounted && _carregandoQuestoes) {
          setState(() => _carregandoQuestoes = false);
        }
      },
    );
  }

  void _tentarCarregarQuestoes() {
    setState(() {
      _carregandoQuestoes = true;
      _erroQuestoes = null;
    });
    _escutarQuestoes();
  }

  void _abrirBancoQuestoes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BancoQuestoesScreen(questaoService: _questaoService),
      ),
    );
  }

  void _alterarQuantidade(int quantidade) {
    setState(() {
      _quantidadeQuestoes = quantidade;
      if (_questoesSelecionadas.length > quantidade) {
        _questoesSelecionadas.removeRange(
          quantidade,
          _questoesSelecionadas.length,
        );
      }
    });
  }

  void _alternarQuestao(Questao questao) {
    if (_questoesSelecionadas.contains(questao.id)) {
      setState(() => _questoesSelecionadas.remove(questao.id));
      return;
    }

    if (_questoesSelecionadas.length >= _quantidadeQuestoes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Limite de $_quantidadeQuestoes questões atingido.'),
        ),
      );
      return;
    }

    setState(() => _questoesSelecionadas.add(questao.id));
  }

  void _avancar() {
    if (!_etapaValida) return;

    if (_etapa < 2) {
      setState(() => _etapa++);
      return;
    }

    _salvar(ProvaStatus.ativa);
  }

  Future<void> _salvar(ProvaStatus status) async {
    final turma = _turma;
    if (turma == null || _salvando || !_etapaValida) return;

    final questoes = _questoesEscolhidas;

    setState(() => _salvando = true);

    try {
      await _provaService.criarProva(
        Prova(
          id: '',
          nome: _nome.trim(),
          turma: turma,
          dataAplicacao: _dataAplicacao,
          quantidadeQuestoes: questoes.length,
          questoes: questoes,
          status: status,
          embaralharQuestoes: _embaralharQuestoes,
          embaralharAlternativas: _embaralharAlternativas,
          numeroVersoes: _numeroVersoes,
          gabaritoOficial: questoes.map((questao) => questao.correta).toList(),
        ),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => _CriandoProvaScreen(
            quantidadeQuestoes: questoes.length,
            rascunho: status == ProvaStatus.rascunho,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final mensagem = e is ArgumentError
          ? '${e.message}'
          : e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  void _voltar() {
    if (_etapa == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _etapa--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _WizardHeader(etapa: _etapa, onBack: _voltar),
            Expanded(
              child: IndexedStack(
                index: _etapa,
                children: [
                  _DadosStep(
                    nome: _nome,
                    turmas: _turmas,
                    carregandoTurmas: _carregandoTurmas,
                    turma: _turma,
                    dataAplicacao: _dataAplicacao,
                    quantidadeQuestoes: _quantidadeQuestoes,
                    onNameChanged: (value) => setState(() => _nome = value),
                    onTurmaChanged: (value) => setState(() => _turma = value),
                    onDateChanged: (value) =>
                        setState(() => _dataAplicacao = value),
                    onQuantityChanged: _alterarQuantidade,
                  ),
                  _QuestoesStep(
                    questoes: _questoesDisponiveis,
                    carregando: _carregandoQuestoes,
                    erro: _erroQuestoes,
                    selecionadas: _questoesSelecionadas,
                    limite: _quantidadeQuestoes,
                    onToggle: _alternarQuestao,
                    onTentarNovamente: _tentarCarregarQuestoes,
                    onAbrirBanco: _abrirBancoQuestoes,
                  ),
                  _GerarStep(
                    nome: _nome,
                    turma: _turma,
                    dataAplicacao: _dataAplicacao,
                    questoesSelecionadas: _questoesSelecionadas.length,
                    embaralharQuestoes: _embaralharQuestoes,
                    embaralharAlternativas: _embaralharAlternativas,
                    numeroVersoes: _numeroVersoes,
                    onShuffleQuestionsChanged: (value) =>
                        setState(() => _embaralharQuestoes = value),
                    onShuffleAlternativesChanged: (value) =>
                        setState(() => _embaralharAlternativas = value),
                    onVersionsChanged: (value) =>
                        setState(() => _numeroVersoes = value),
                  ),
                ],
              ),
            ),
            _WizardFooter(
              etapa: _etapa,
              salvando: _salvando,
              onContinue: _etapaValida && !_salvando ? _avancar : null,
              onSaveDraft: _etapaValida && !_salvando
                  ? () => _salvar(ProvaStatus.rascunho)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _WizardHeader extends StatelessWidget {
  final int etapa;
  final VoidCallback onBack;

  const _WizardHeader({required this.etapa, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 29),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE4E9F1))),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 17,
                  color: Color(0xFF4E47EF),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 22),
              const Text(
                'Nova Prova',
                style: TextStyle(
                  color: Color(0xFF101827),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 49,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            children: [
              _StepIndicator(
                number: 1,
                label: 'Dados',
                active: etapa >= 0,
                completed: etapa > 0,
              ),
              const _StepLine(),
              _StepIndicator(
                number: 2,
                label: 'Questões',
                active: etapa >= 1,
                completed: etapa > 1,
              ),
              const _StepLine(),
              _StepIndicator(
                number: 3,
                label: 'Gerar',
                active: etapa >= 2,
                completed: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int number;
  final String label;
  final bool active;
  final bool completed;

  const _StepIndicator({
    required this.number,
    required this.label,
    required this.active,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF5547EA) : const Color(0xFFF0F3F7),
          shape: BoxShape.circle,
        ),
        child: Text(
          completed ? '✓' : '$number',
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF9BA9BA),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(width: 7),
      Text(
        label,
        style: TextStyle(
          color: active ? const Color(0xFF4D43E8) : const Color(0xFF9BA9BA),
          fontSize: 11,
          fontWeight: active ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    ],
  );
}

class _StepLine extends StatelessWidget {
  const _StepLine();

  @override
  Widget build(BuildContext context) => const Expanded(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Divider(color: Color(0xFFDCE2EA), thickness: 1),
    ),
  );
}

class _DadosStep extends StatelessWidget {
  final String nome;
  final List<Turma> turmas;
  final bool carregandoTurmas;
  final Turma? turma;
  final DateTime dataAplicacao;
  final int quantidadeQuestoes;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<Turma?> onTurmaChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int> onQuantityChanged;

  const _DadosStep({
    required this.nome,
    required this.turmas,
    required this.carregandoTurmas,
    required this.turma,
    required this.dataAplicacao,
    required this.quantidadeQuestoes,
    required this.onNameChanged,
    required this.onTurmaChanged,
    required this.onDateChanged,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(28, 16, 15, 25),
    children: [
      _FormCard(
        children: [
          const _FieldLabel('NOME DA PROVA'),
          TextField(
            onChanged: onNameChanged,
            decoration: _inputDecoration('Ex: 1ª Prova Bimestral — Citologia'),
          ),
          const SizedBox(height: 16),
          const _FieldLabel('TURMA'),
          if (carregandoTurmas)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(color: Color(0xFF5547EA)),
            )
          else if (turmas.isEmpty)
            const Text(
              'Nenhuma turma cadastrada. Cadastre uma turma antes de criar a prova.',
              style: TextStyle(color: Color(0xFFB65D2E), fontSize: 12),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: turma?.id,
              hint: const Text('Selecione a turma'),
              items: [
                for (final item in turmas)
                  DropdownMenuItem(
                    value: item.id,
                    child: Text(
                      '${item.nome} — ${item.ano} (${item.totalAlunos} alunos)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (id) => onTurmaChanged(
                turmas.where((item) => item.id == id).firstOrNull,
              ),
              decoration: _inputDecoration(''),
            ),
          const SizedBox(height: 16),
          const _FieldLabel('DATA DE APLICAÇÃO'),
          InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () async {
              final escolhida = await showDatePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime(DateTime.now().year + 5),
                initialDate: dataAplicacao,
              );
              if (escolhida != null) onDateChanged(escolhida);
            },
            child: InputDecorator(
              decoration: _inputDecoration(
                'dd/mm/aaaa',
                suffixIcon: Icons.calendar_month_outlined,
              ),
              child: Text(
                _formatarData(dataAplicacao),
                style: const TextStyle(color: Color(0xFF101827), fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _FieldLabel('NÚMERO DE QUESTÕES'),
          Row(
            children: [
              for (final quantidade in [5, 10, 15, 20]) ...[
                if (quantidade != 5) const SizedBox(width: 8),
                Expanded(
                  child: _ChoiceButton(
                    label: '$quantidade',
                    selected: quantidadeQuestoes == quantidade,
                    onTap: () => onQuantityChanged(quantidade),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ],
  );
}

class _QuestoesStep extends StatelessWidget {
  final List<Questao> questoes;
  final bool carregando;
  final Object? erro;
  final List<String> selecionadas;
  final int limite;
  final ValueChanged<Questao> onToggle;
  final VoidCallback onTentarNovamente;
  final VoidCallback onAbrirBanco;

  const _QuestoesStep({
    required this.questoes,
    required this.carregando,
    required this.erro,
    required this.selecionadas,
    required this.limite,
    required this.onToggle,
    required this.onTentarNovamente,
    required this.onAbrirBanco,
  });

  Widget _aviso({
    required IconData icone,
    required Color cor,
    required String titulo,
    required String mensagem,
    required String acao,
    required VoidCallback onAcao,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, size: 48, color: cor),
          const SizedBox(height: 12),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF101827),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF91A0B5), fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onAcao,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5547EA),
              foregroundColor: Colors.white,
            ),
            child: Text(acao),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5547EA)),
      );
    }

    if (erro != null) {
      return _aviso(
        icone: Icons.error_outline_rounded,
        cor: const Color(0xFFE53935),
        titulo: 'Não foi possível carregar as questões.',
        mensagem: '$erro',
        acao: 'Tentar novamente',
        onAcao: onTentarNovamente,
      );
    }

    if (questoes.isEmpty) {
      return _aviso(
        icone: Icons.quiz_outlined,
        cor: const Color(0xFF91A0B5),
        titulo: 'Nenhuma questão no banco',
        mensagem: 'Cadastre questões no banco para incluí-las na prova.',
        acao: 'Abrir banco de questões',
        onAcao: onAbrirBanco,
      );
    }

    return _lista();
  }

  Widget _lista() => ListView(
    padding: const EdgeInsets.fromLTRB(22, 17, 22, 25),
    children: [
      Text(
        'BANCO DE QUESTÕES — SELECIONE ATÉ $limite',
        style: const TextStyle(
          color: Color(0xFF52647C),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: .3,
        ),
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(
            child: Text(
              '${selecionadas.length} de $limite questões selecionadas',
              style: const TextStyle(color: Color(0xFF91A0B5), fontSize: 11),
            ),
          ),
          TextButton(
            onPressed: onAbrirBanco,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF5146EE),
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
            ),
            child: const Text(
              'Gerenciar banco',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      for (var index = 0; index < questoes.length; index++) ...[
        _QuestionCard(
          question: questoes[index],
          ordem: selecionadas.contains(questoes[index].id)
              ? selecionadas.indexOf(questoes[index].id) + 1
              : null,
          onTap: () => onToggle(questoes[index]),
        ),
        if (index < questoes.length - 1) const SizedBox(height: 10),
      ],
    ],
  );
}

class _QuestionCard extends StatelessWidget {
  final Questao question;
  final int? ordem;
  final VoidCallback onTap;

  const _QuestionCard({
    required this.question,
    required this.ordem,
    required this.onTap,
  });

  bool get selected => ordem != null;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(15),
    child: Container(
      padding: const EdgeInsets.all(13),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 19,
            height: 19,
            margin: const EdgeInsets.only(top: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF5547EA)
                  : const Color(0xFFF5F8FB),
              border: Border.all(
                color: selected
                    ? const Color(0xFF5547EA)
                    : const Color(0xFFCBD8E5),
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: selected
                ? Text(
                    '$ordem',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.enunciado,
                  style: const TextStyle(
                    color: Color(0xFF355173),
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 7,
                  runSpacing: 5,
                  children: [
                    _Tag(
                      question.assunto,
                      const Color(0xFFE7E9FF),
                      const Color(0xFF443CE1),
                    ),
                    _Tag(
                      question.dificuldade,
                      const Color(0xFFD4F8E7),
                      const Color(0xFF07865D),
                    ),
                    _Tag(
                      'Gabarito: ${question.correta}',
                      const Color(0xFFE6FAF0),
                      const Color(0xFF16825D),
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

class _GerarStep extends StatelessWidget {
  final String nome;
  final Turma? turma;
  final DateTime dataAplicacao;
  final int questoesSelecionadas;
  final bool embaralharQuestoes;
  final bool embaralharAlternativas;
  final int numeroVersoes;
  final ValueChanged<bool> onShuffleQuestionsChanged;
  final ValueChanged<bool> onShuffleAlternativesChanged;
  final ValueChanged<int> onVersionsChanged;

  const _GerarStep({
    required this.nome,
    required this.turma,
    required this.dataAplicacao,
    required this.questoesSelecionadas,
    required this.embaralharQuestoes,
    required this.embaralharAlternativas,
    required this.numeroVersoes,
    required this.onShuffleQuestionsChanged,
    required this.onShuffleAlternativesChanged,
    required this.onVersionsChanged,
  });

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(28, 16, 15, 25),
    children: [
      _FormCard(
        children: [
          const Text(
            'Configurações de geração',
            style: TextStyle(
              color: Color(0xFF101827),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _SwitchLine(
            title: 'Embaralhar questões',
            subtitle: 'Altera a ordem das questões entre versões',
            value: embaralharQuestoes,
            onChanged: onShuffleQuestionsChanged,
          ),
          _SwitchLine(
            title: 'Embaralhar alternativas',
            subtitle: 'Altera a ordem das alternativas A–E',
            value: embaralharAlternativas,
            onChanged: onShuffleAlternativesChanged,
          ),
          const SizedBox(height: 5),
          const _FieldLabel('NÚMERO DE VERSÕES'),
          Row(
            children: [
              for (final versoes in [1, 2, 4]) ...[
                if (versoes != 1) const SizedBox(width: 8),
                Expanded(
                  child: _ChoiceButton(
                    label: '$versoes ${versoes == 1 ? 'versão' : 'versões'}',
                    selected: numeroVersoes == versoes,
                    onTap: () => onVersionsChanged(versoes),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      const SizedBox(height: 15),
      _SummaryCard(
        nome: nome,
        turma: turma,
        dataAplicacao: dataAplicacao,
        quantidadeQuestoes: questoesSelecionadas,
        numeroVersoes: numeroVersoes,
      ),
    ],
  );
}

class _SwitchLine extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchLine({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Color(0xFF101827), fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF91A0B5), fontSize: 10),
            ),
          ],
        ),
      ),
      Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: const Color(0xFF5547EA),
      ),
    ],
  );
}

class _SummaryCard extends StatelessWidget {
  final String nome;
  final Turma? turma;
  final DateTime dataAplicacao;
  final int quantidadeQuestoes;
  final int numeroVersoes;

  const _SummaryCard({
    required this.nome,
    required this.turma,
    required this.dataAplicacao,
    required this.quantidadeQuestoes,
    required this.numeroVersoes,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF3FF),
      border: Border.all(color: const Color(0xFFC6D3FF)),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumo',
          style: TextStyle(
            color: Color(0xFF2437C2),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _SummaryRow('Nome', nome.trim().isEmpty ? 'Não informado' : nome),
        _SummaryRow('Turma', turma?.nome ?? 'Não informada'),
        _SummaryRow('Data', _formatarData(dataAplicacao)),
        _SummaryRow('Questões selecionadas', '$quantidadeQuestoes'),
        _SummaryRow('Versões', '$numeroVersoes'),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFC6D3FF))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF4C58C9), fontSize: 10),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2638B7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WizardFooter extends StatelessWidget {
  final int etapa;
  final bool salvando;
  final VoidCallback? onContinue;
  final VoidCallback? onSaveDraft;

  const _WizardFooter({
    required this.etapa,
    required this.salvando,
    required this.onContinue,
    required this.onSaveDraft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 15, 23),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E9F1))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 46,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6040EB),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFD8D4F8),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: salvando
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      etapa == 2 ? 'Gerar prova' : 'Continuar',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          if (etapa == 2) ...[
            const SizedBox(height: 6),
            TextButton(
              onPressed: onSaveDraft,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5146EE),
              ),
              child: const Text(
                'Salvar como rascunho',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CriandoProvaScreen extends StatefulWidget {
  final int quantidadeQuestoes;
  final bool rascunho;

  const _CriandoProvaScreen({
    required this.quantidadeQuestoes,
    required this.rascunho,
  });

  @override
  State<_CriandoProvaScreen> createState() => _CriandoProvaScreenState();
}

class _CriandoProvaScreenState extends State<_CriandoProvaScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ProvasScreen()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 74,
                height: 74,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFD2F8E7),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.check, color: Colors.black, size: 35),
              ),
              const SizedBox(height: 18),
              Text(
                widget.rascunho ? 'Rascunho salvo!' : 'Prova criada!',
                style: const TextStyle(
                  color: Color(0xFF101827),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.quantidadeQuestoes == 1
                    ? 'A prova foi salva com 1 questão.'
                    : 'A prova foi salva com ${widget.quantidadeQuestoes} questões.',
                style: const TextStyle(color: Color(0xFF667A96), fontSize: 13),
              ),
              const SizedBox(height: 18),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF5547EA),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;

  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(15, 17, 15, 15),
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
      children: children,
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xFF52647C),
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: .4,
      ),
    ),
  );
}

String _formatarData(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

InputDecoration _inputDecoration(String hint, {IconData? suffixIcon}) =>
    InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon == null
          ? null
          : Icon(suffixIcon, size: 16, color: const Color(0xFF101827)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFDCE2EA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFDCE2EA)),
      ),
      hintStyle: const TextStyle(color: Color(0xFF8292A9), fontSize: 12),
    );

class _ChoiceButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF5547EA) : const Color(0xFFF1F4F8),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF667A96),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Tag(this.label, this.background, this.foreground);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: foreground,
        fontSize: 9,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
