import 'package:flutter/material.dart';

import '../models/prova.dart';
import 'correcao_concluida_screen.dart';

class FolhasScreen extends StatefulWidget {
  final Prova prova;

  // Gabarito vindo do QR Code lido no passo anterior.
  final List<String> gabarito;

  const FolhasScreen({super.key, required this.prova, required this.gabarito});

  @override
  State<FolhasScreen> createState() => _FolhasScreenState();
}

class _FolhasScreenState extends State<FolhasScreen> {
  // ============================================================
  // RESULTADOS DAS FOLHAS LIDAS PELA CÂMERA
  // ============================================================

  final List<Map<String, dynamic>> _folhasLidas = [];

  bool _abrindoLeitor = false;

  // Fluxo mockado: uma folha de um aluno fictício basta para validar a etapa de correção.
  int get _totalFolhas => 1;

  bool get _todasLidas {
    return _folhasLidas.length >= _totalFolhas;
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
  // ABRIR A CÂMERA PARA LER A PRÓXIMA FOLHA
  // ============================================================

  Future<void> _lerProximaFolha() async {
    if (_abrindoLeitor || _todasLidas) {
      return;
    }

    setState(() {
      _abrindoLeitor = true;
    });

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) {
      return;
    }

    final gabarito = widget.gabarito;
    final respostas = <String>[];

    for (int i = 0; i < gabarito.length; i++) {
      final alternativa = ['A', 'B', 'C', 'D', 'E'][i % 5];
      respostas.add(i % 2 == 0 ? gabarito[i] : alternativa);
    }

    int acertos = 0;
    for (int i = 0; i < respostas.length; i++) {
      if (i < gabarito.length && respostas[i] == gabarito[i]) {
        acertos++;
      }
    }

    final novoResultado = <String, dynamic>{
      'aluno': 'Ana Souza',
      'matricula': '2026001',
      'respostas': respostas,
      'gabarito': gabarito,
      'acertos': acertos,
      'total': gabarito.length,
      'numeroFolha': 1,
    };

    setState(() {
      _abrindoLeitor = false;
      _folhasLidas.add(novoResultado);
    });
  }

  // ============================================================
  // FINALIZAR CORREÇÃO
  // ============================================================

  void _finalizar() {
    if (!_todasLidas) {
      return;
    }

    int totalAcertos = 0;
    int totalQuestoes = 0;

    for (final folha in _folhasLidas) {
      totalAcertos += _acertos(folha);
      totalQuestoes += _totalQuestoes(folha);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CorrecaoConcluidaScreen(
          prova: widget.prova,
          folhasCorrigidas: _folhasLidas.length,
          totalAcertos: totalAcertos,
          totalQuestoes: totalQuestoes,
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
                : 'A câmera captura a folha e analisa as respostas.',
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 11, 18, 14),
      color: Colors.white,
      child: SizedBox(
        height: 42,
        child: ElevatedButton(
          onPressed: _abrindoLeitor
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
            _abrindoLeitor
                ? 'Abrindo câmera...'
                : terminou
                ? 'Finalizar correção'
                : 'Ler folha',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
