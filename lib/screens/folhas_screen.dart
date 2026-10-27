import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/aluno.dart';
import '../models/prova.dart';
import '../models/resultado.dart';
import '../services/resultado_service.dart';
import '../services/turma_service.dart';
import 'correcao_concluida_screen.dart';

class FolhasScreen extends StatefulWidget {
  final Prova prova;

  // Gabarito vindo do QR Code lido no passo anterior.
  final List<String> gabarito;

  final TurmaService? turmaService;
  final ResultadoService? resultadoService;

  const FolhasScreen({
    super.key,
    required this.prova,
    required this.gabarito,
    this.turmaService,
    this.resultadoService,
  });

  @override
  State<FolhasScreen> createState() => _FolhasScreenState();
}

class _FolhasScreenState extends State<FolhasScreen> {
  // ============================================================
  // RESULTADOS DAS FOLHAS LIDAS PELA CÂMERA
  // ============================================================

  final List<Map<String, dynamic>> _folhasLidas = [];

  // Alunos da turma da prova: cada folha lida pertence ao próximo aluno da lista.
  List<Aluno> _alunos = [];
  bool _carregandoAlunos = true;

  bool _abrindoLeitor = false;
  bool _salvando = false;

  int get _totalFolhas => _alunos.isEmpty ? 1 : _alunos.length;

  bool get _todasLidas {
    return _folhasLidas.length >= _totalFolhas;
  }

  @override
  void initState() {
    super.initState();
    _carregarAlunos();
  }

  // ============================================================
  // ALUNOS DA TURMA
  // ============================================================

  Future<void> _carregarAlunos() async {
    var alunos = <Aluno>[];

    try {
      final service = widget.turmaService ?? TurmaService();
      alunos = await service.listarAlunos(turmaId: widget.prova.turma.id);
    } catch (_) {
      // Sem Firebase/sessão ou turma inexistente no Firestore: usa os alunos da prova.
    }

    if (alunos.isEmpty) alunos = List.of(widget.prova.turma.alunos);
    alunos.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

    if (!mounted) return;
    setState(() {
      _alunos = alunos;
      _carregandoAlunos = false;
    });
  }

  Aluno _alunoDaFolha(int indice) {
    if (indice < _alunos.length) return _alunos[indice];
    return Aluno(
      id: 'folha_${indice + 1}',
      nome: 'Aluno ${indice + 1}',
      ra: '${indice + 1}'.padLeft(6, '0'),
    );
  }

  // ============================================================
  // QUANTIDADE DE ACERTOS
  // ============================================================

  int _acertos(Map<String, dynamic> folha) {
    return folha['acertos'] as int? ?? 0;
  }

  int _totalQuestoes(Map<String, dynamic> folha) {
    return folha['total'] as int? ?? 0;
  }

  // ============================================================
  // LER A PRÓXIMA FOLHA
  // ============================================================

  Future<void> _lerProximaFolha() async {
    if (_abrindoLeitor || _todasLidas || _carregandoAlunos) {
      return;
    }

    setState(() {
      _abrindoLeitor = true;
    });

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) {
      return;
    }

    final aluno = _alunoDaFolha(_folhasLidas.length);
    final gabarito = widget.gabarito;

    // Leitura simulada: cada aluno tem um padrão de respostas próprio e estável,
    // acertando cerca de 70% das questões.
    final random = math.Random(Object.hash(aluno.id, widget.prova.id));
    final respostas = <String>[
      for (final correta in gabarito)
        random.nextDouble() < .7
            ? correta
            : (['A', 'B', 'C', 'D']..remove(correta))[random.nextInt(3)],
    ];

    final resultado = ResultadoAluno.corrigir(
      aluno: aluno,
      respostas: respostas,
      gabarito: gabarito,
    );

    final novoResultado = <String, dynamic>{
      'alunoObj': aluno,
      'aluno': aluno.nome,
      'matricula': aluno.ra,
      'respostas': resultado.alternativasMarcadas,
      'gabarito': gabarito,
      'acertos': resultado.acertos,
      'total': gabarito.length,
      'numeroFolha': _folhasLidas.length + 1,
    };

    setState(() {
      _abrindoLeitor = false;
      _folhasLidas.add(novoResultado);
    });
  }

  // ============================================================
  // FINALIZAR CORREÇÃO
  // ============================================================

  Future<void> _finalizar() async {
    if (_folhasLidas.isEmpty || _salvando) {
      return;
    }

    setState(() => _salvando = true);

    int totalAcertos = 0;
    int totalQuestoes = 0;

    for (final folha in _folhasLidas) {
      totalAcertos += _acertos(folha);
      totalQuestoes += _totalQuestoes(folha);
    }

    final resultados = [
      for (final folha in _folhasLidas)
        ResultadoAluno.corrigir(
          aluno: folha['alunoObj'] as Aluno,
          respostas: List<String>.from(folha['respostas'] as List),
          gabarito: widget.gabarito,
          provaId: widget.prova.id,
          turmaId: widget.prova.turma.id,
        ),
    ];

    var salvo = true;
    ResultadoProva resultado;
    try {
      final service = widget.resultadoService ?? ResultadoService();
      resultado = await service.salvarCorrecao(
        prova: widget.prova,
        gabarito: widget.gabarito,
        resultados: resultados,
      );
    } catch (_) {
      salvo = false;
      resultado = ResultadoProva.calcular(
        prova: widget.prova,
        gabarito: widget.gabarito,
        porAluno: resultados,
      );
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CorrecaoConcluidaScreen(
          prova: widget.prova,
          folhasCorrigidas: _folhasLidas.length,
          totalAcertos: totalAcertos,
          totalQuestoes: totalQuestoes,
          resultado: resultado,
          salvo: salvo,
        ),
      ),
    );
  }

  // ============================================================
  // TELA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 25),
                child: Column(
                  children: [
                    _buildProgresso(),

                    const SizedBox(height: 14),

                    _buildLeituraCard(),

                    const SizedBox(height: 14),

                    ..._buildResultados(),

                    if (_folhasLidas.isEmpty) _buildMensagemInicial(),
                  ],
                ),
              ),
            ),

            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CABEÇALHO
  // ============================================================

  Widget _buildHeader() {
    return Container(
      height: 57,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E9F1))),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 17,
                color: Color(0xFF4F43D8),
              ),
            ),
          ),

          const SizedBox(width: 14),

          const Text(
            'Passo 2: Folhas',
            style: TextStyle(
              color: Color(0xFF101827),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROGRESSO
  // ============================================================

  Widget _buildProgresso() {
    final progresso = (_folhasLidas.length / _totalFolhas).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Folhas de resposta',
                  style: TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Text(
                '${_folhasLidas.length}/$_totalFolhas',
                style: const TextStyle(
                  color: Color(0xFF5747E8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 6,
              backgroundColor: const Color(0xFFE8EBF2),
              color: const Color(0xFF5B49E8),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD DE LEITURA
  // ============================================================

  Widget _buildLeituraCard() {
    final terminou = _todasLidas;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 15, 14, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 130,
            height: 155,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDE2EB)),
            ),
            child: Icon(
              terminou
                  ? Icons.check_circle_rounded
                  : Icons.document_scanner_outlined,
              color: terminou
                  ? const Color(0xFF17A978)
                  : const Color(0xFF5B49E8),
              size: 65,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            terminou
                ? 'Todas as folhas foram lidas'
                : 'Leitura da folha de resposta',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: terminou
                  ? const Color(0xFF14996F)
                  : const Color(0xFF263247),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            terminou
                ? 'Você já pode finalizar a correção.'
                : _carregandoAlunos
                ? 'Carregando alunos da turma...'
                : 'Próxima folha: ${_alunoDaFolha(_folhasLidas.length).nome}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF8994A6), fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESULTADOS
  // ============================================================

  List<Widget> _buildResultados() {
    final widgets = <Widget>[];

    for (int i = 0; i < _folhasLidas.length; i++) {
      widgets.add(_buildResultadoFolha(_folhasLidas[i]));

      if (i < _folhasLidas.length - 1) {
        widgets.add(const SizedBox(height: 12));
      }
    }

    return widgets;
  }

  Widget _buildResultadoFolha(Map<String, dynamic> folha) {
    final respostas = List<String>.from(folha['respostas'] ?? <String>[]);

    final gabarito = List<String>.from(folha['gabarito'] ?? <String>[]);

    final acertos = folha['acertos'] as int? ?? 0;

    final total = folha['total'] as int? ?? gabarito.length;

    final percentual = total == 0 ? 0 : (acertos / total * 100).round();

    final aluno = folha['aluno']?.toString() ?? 'Aluno';

    final matricula = folha['matricula']?.toString() ?? '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF9F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBDE8D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF16A374),
                size: 21,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  aluno,
                  style: const TextStyle(
                    color: Color(0xFF17684F),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Text(
                '$acertos/$total',
                style: const TextStyle(
                  color: Color(0xFF17684F),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            'Matrícula: $matricula',
            style: const TextStyle(color: Color(0xFF6D8A7F), fontSize: 9),
          ),

          const SizedBox(height: 9),

          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : acertos / total,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFD8EEE6),
                  color: const Color(0xFF18A97D),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),

              const SizedBox(width: 9),

              Text(
                '$percentual%',
                style: const TextStyle(
                  color: Color(0xFF17684F),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(respostas.length, (index) {
              final resposta = respostas[index];

              final respostaGabarito = index < gabarito.length
                  ? gabarito[index]
                  : '?';

              final correta = resposta == respostaGabarito;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                decoration: BoxDecoration(
                  color: correta
                      ? const Color(0xFFD8F3E8)
                      : const Color(0xFFFDE4E5),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  'Q${index + 1}  $resposta',
                  style: TextStyle(
                    color: correta
                        ? const Color(0xFF12815E)
                        : const Color(0xFFBF404A),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MENSAGEM INICIAL
  // ============================================================

  Widget _buildMensagemInicial() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFD0D7FF)),
      ),
      child: const Text(
        'Nenhuma folha foi lida ainda. '
        'Toque em "Ler folha" para iniciar.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF59667B), fontSize: 10, height: 1.35),
      ),
    );
  }

  // ============================================================
  // BOTÃO INFERIOR
  // ============================================================

  Widget _buildBottomButton() {
    final terminou = _todasLidas;
    final ocupado = _abrindoLeitor || _salvando || _carregandoAlunos;
    final podeFinalizarParcial = !terminou && _folhasLidas.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 11, 18, 14),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Alunos ausentes: permite encerrar sem ler todas as folhas da turma.
          // Fica acima do botão principal para ele não mudar de lugar.
          if (podeFinalizarParcial)
            TextButton(
              onPressed: ocupado ? null : _finalizar,
              child: Text(
                'Finalizar com ${_folhasLidas.length} '
                '${_folhasLidas.length == 1 ? 'folha' : 'folhas'}',
                style: const TextStyle(
                  color: Color(0xFF5647E8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: ocupado
                  ? null
                  : terminou
                  ? _finalizar
                  : _lerProximaFolha,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5647E8),
                disabledBackgroundColor: const Color(0xFFD8DAE3),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _salvando
                    ? 'Salvando resultados...'
                    : _abrindoLeitor
                    ? 'Lendo folha...'
                    : terminou
                    ? 'Finalizar correção'
                    : 'Ler folha',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
