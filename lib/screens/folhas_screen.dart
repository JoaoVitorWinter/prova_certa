import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/aluno.dart';
import '../models/prova.dart';
import '../models/resultado.dart';
import '../services/leitura_folha_service.dart';
import '../services/resultado_service.dart';
import '../services/turma_service.dart';
import 'correcao_concluida_screen.dart';

class FolhasScreen extends StatefulWidget {
  final Prova prova;
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
  final List<Map<String, dynamic>> _folhasLidas = [];
  List<Aluno> _alunos = [];
  final Set<String> _alunosCorrigidosIds = {};
  bool _carregandoAlunos = true;
  bool _abrindoLeitor = false;
  bool _salvando = false;

  int get _totalFolhas => _alunos.isEmpty ? 1 : _alunos.length;
  bool get _todasLidas => _folhasLidas.length >= _totalFolhas;

  @override
  void initState() {
    super.initState();
    _carregarAlunos();
  }

  Future<void> _carregarAlunos() async {
    var alunos = <Aluno>[];
    try {
      final service = widget.turmaService ?? TurmaService();
      alunos = await service.listarAlunos(turmaId: widget.prova.turma.id);
    } catch (_) {
      // Usa a lista de alunos da prova como alternativa.
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

  int _acertos(Map<String, dynamic> folha) => folha['acertos'] as int? ?? 0;
  int _totalQuestoes(Map<String, dynamic> folha) => folha['total'] as int? ?? 0;

  Future<void> _lerProximaFolha() async {
    if (_abrindoLeitor || _todasLidas || _carregandoAlunos) return;
    setState(() => _abrindoLeitor = true);

    try {
      final bytes = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(builder: (_) => const _CapturarFolhaScreen()),
      );
      if (!mounted || bytes == null) return;

      // O nome manuscrito ainda não é reconhecido automaticamente por OCR.
      // O professor confirma o aluno correspondente à folha fotografada.
      final aluno = await _selecionarAluno();
      if (!mounted || aluno == null) return;

      List<String?> detetadas;
      try {
        detetadas = LeituraFolhaService().lerRespostas(
          bytesImagem: bytes,
          quantidadeQuestoes: widget.gabarito.length,
        );
      } catch (e) {
        _mensagem('Não foi possível analisar a fotografia: $e');
        return;
      }

      if (!mounted) return;
      final confirmadas = await Navigator.push<List<String?>>(
        context,
        MaterialPageRoute(
          builder: (_) => _ConferirRespostasScreen(
            respostas: detetadas,
            nomeAluno: aluno.nome,
          ),
        ),
      );
      if (!mounted || confirmadas == null) return;

      final respostas = confirmadas.map((r) => r ?? '').toList();
      final resultado = ResultadoAluno.corrigir(
        aluno: aluno,
        respostas: respostas,
        gabarito: widget.gabarito,
      );

      setState(() {
        _alunosCorrigidosIds.add(aluno.id);
        _folhasLidas.add({
          'alunoObj': aluno,
          'aluno': aluno.nome,
          'matricula': aluno.ra,
          'respostas': respostas,
          'gabarito': widget.gabarito,
          'acertos': resultado.acertos,
          'total': widget.gabarito.length,
          'numeroFolha': _folhasLidas.length + 1,
        });
      });
    } catch (e) {
      if (mounted) _mensagem('Erro ao abrir a câmara: $e');
    } finally {
      if (mounted) setState(() => _abrindoLeitor = false);
    }
  }

  Future<Aluno?> _selecionarAluno() async {
    final pendentes = _alunos
        .where((aluno) => !_alunosCorrigidosIds.contains(aluno.id))
        .toList();

    if (pendentes.isEmpty) {
      if (_alunos.isEmpty) return _alunoDaFolha(_folhasLidas.length);
      _mensagem('Todos os alunos da turma já foram corrigidos.');
      return null;
    }

    return showDialog<Aluno>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar aluno'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'Confirme o nome escrito na folha fotografada:',
                ),
              ),
              ...pendentes.map(
                (aluno) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(aluno.nome),
                  subtitle: Text('Matrícula: ${aluno.ra}'),
                  onTap: () => Navigator.pop(dialogContext, aluno),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), duration: const Duration(seconds: 4)),
    );
  }

  Future<void> _finalizar() async {
    if (_folhasLidas.isEmpty || _salvando) return;
    setState(() => _salvando = true);

    var totalAcertos = 0;
    var totalQuestoes = 0;
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
    late ResultadoProva resultado;
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
        builder: (_) => CorrecaoConcluidaScreen(
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

  Widget _buildHeader() => Container(
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
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 17, color: Color(0xFF4F43D8)),
              ),
            ),
            const SizedBox(width: 14),
            const Text('Passo 2: Folhas',
                style: TextStyle(
                    color: Color(0xFF101827),
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _buildProgresso() {
    final progresso = (_folhasLidas.length / _totalFolhas).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Expanded(
                child: Text('Folhas de resposta',
                    style: TextStyle(
                        color: Color(0xFF172033),
                        fontSize: 12,
                        fontWeight: FontWeight.w700))),
            Text('${_folhasLidas.length}/$_totalFolhas',
                style: const TextStyle(
                    color: Color(0xFF5747E8),
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
                value: progresso,
                minHeight: 6,
                backgroundColor: const Color(0xFFE8EBF2),
                color: const Color(0xFF5B49E8)),
          ),
        ],
      ),
    );
  }

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
              color: Color(0x0D000000), blurRadius: 7, offset: Offset(0, 2))
        ],
      ),
      child: Column(children: [
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
              : 'Captura e conferência da folha',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: terminou
                  ? const Color(0xFF14996F)
                  : const Color(0xFF263247),
              fontSize: 12,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 7),
        Text(
          terminou
              ? 'Você já pode finalizar a correção.'
              : _carregandoAlunos
                  ? 'Carregando alunos da turma...'
                  : 'Folha ${_folhasLidas.length + 1}: confirme o nome do aluno',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF8994A6), fontSize: 10),
        ),
      ]),
    );
  }

  List<Widget> _buildResultados() {
    final widgets = <Widget>[];
    for (var i = 0; i < _folhasLidas.length; i++) {
      widgets.add(_buildResultadoFolha(_folhasLidas[i]));
      if (i < _folhasLidas.length - 1) widgets.add(const SizedBox(height: 12));
    }
    return widgets;
  }

  Widget _buildResultadoFolha(Map<String, dynamic> folha) {
    final respostas = List<String>.from(folha['respostas'] ?? <String>[]);
    final gabarito = List<String>.from(folha['gabarito'] ?? <String>[]);
    final acertos = folha['acertos'] as int? ?? 0;
    final total = folha['total'] as int? ?? gabarito.length;
    final percentual = total == 0 ? 0 : (acertos / total * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF9F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBDE8D8)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF16A374), size: 21),
          const SizedBox(width: 8),
          Expanded(
            child: Text(folha['aluno']?.toString() ?? 'Aluno',
                style: const TextStyle(
                    color: Color(0xFF17684F),
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          Text('$acertos/$total',
              style: const TextStyle(
                  color: Color(0xFF17684F),
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 4),
        Text('Matrícula: ${folha['matricula'] ?? '-'}',
            style: const TextStyle(color: Color(0xFF6D8A7F), fontSize: 9)),
        const SizedBox(height: 9),
        Row(children: [
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
          Text('$percentual%',
              style: const TextStyle(
                  color: Color(0xFF17684F),
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(respostas.length, (index) {
            final resposta = respostas[index].isEmpty ? '—' : respostas[index];
            final correta =
                index < gabarito.length && resposta == gabarito[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
              decoration: BoxDecoration(
                color: correta
                    ? const Color(0xFFD8F3E8)
                    : const Color(0xFFFDE4E5),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text('Q${index + 1}  $resposta',
                  style: TextStyle(
                      color: correta
                          ? const Color(0xFF12815E)
                          : const Color(0xFFBF404A),
                      fontSize: 8,
                      fontWeight: FontWeight.w700)),
            );
          }),
        ),
      ]),
    );
  }

  Widget _buildMensagemInicial() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFD0D7FF)),
        ),
        child: const Text(
          'Fotografe a folha inteira, confirme o aluno pelo nome escrito na folha '
          'e confira as respostas detetadas antes de guardar a correção.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Color(0xFF59667B), fontSize: 10, height: 1.35),
        ),
      );

  Widget _buildBottomButton() {
    final terminou = _todasLidas;
    final ocupado = _abrindoLeitor || _salvando || _carregandoAlunos;
    final podeFinalizarParcial = !terminou && _folhasLidas.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 11, 18, 14),
      color: Colors.white,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (podeFinalizarParcial)
          TextButton(
            onPressed: ocupado ? null : _finalizar,
            child: Text(
              'Finalizar com ${_folhasLidas.length} '
              '${_folhasLidas.length == 1 ? 'folha' : 'folhas'}',
              style: const TextStyle(
                  color: Color(0xFF5647E8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
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
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _salvando
                  ? 'Salvando resultados...'
                  : _abrindoLeitor
                      ? 'Abrindo câmara...'
                      : terminou
                          ? 'Finalizar correção'
                          : 'Fotografar folha',
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ]),
    );
  }
}

class _CapturarFolhaScreen extends StatefulWidget {
  const _CapturarFolhaScreen();

  @override
  State<_CapturarFolhaScreen> createState() => _CapturarFolhaScreenState();
}

class _CapturarFolhaScreenState extends State<_CapturarFolhaScreen> {
  CameraController? _controller;
  bool _inicializando = true;
  bool _capturando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _iniciarCamera();
  }

  Future<void> _iniciarCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('Não foi encontrada nenhuma câmara neste dispositivo.');
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _inicializando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString();
        _inicializando = false;
      });
    }
  }

  Future<void> _capturar() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturando) {
      return;
    }
    setState(() => _capturando = true);
    try {
      final ficheiro = await controller.takePicture();
      final bytes = await ficheiro.readAsBytes();
      if (!mounted) return;
      Navigator.pop(context, bytes);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível tirar a fotografia: $e';
        _capturando = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Fotografar folha'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
      ),
      body: _inicializando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_erro!,
                        style: const TextStyle(color: Colors.white)),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: controller != null &&
                              controller.value.isInitialized
                          ? Center(
                              child: AspectRatio(
                                aspectRatio: controller.value.aspectRatio,
                                child: CameraPreview(controller),
                              ),
                            )
                          : const Center(
                              child: Text('Câmara indisponível',
                                  style: TextStyle(color: Colors.white)),
                            ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                        'Enquadre a folha inteira, mantenha o telemóvel direito '
                        'e use boa iluminação.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _capturando ? null : _capturar,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(
                              _capturando ? 'A capturar...' : 'Capturar folha'),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _ConferirRespostasScreen extends StatefulWidget {
  final List<String?> respostas;
  final String nomeAluno;

  const _ConferirRespostasScreen({
    required this.respostas,
    required this.nomeAluno,
  });

  @override
  State<_ConferirRespostasScreen> createState() =>
      _ConferirRespostasScreenState();
}

class _ConferirRespostasScreenState extends State<_ConferirRespostasScreen> {
  late List<String?> _respostas;
  static const _opcoes = ['A', 'B', 'C', 'D', 'E'];

  @override
  void initState() {
    super.initState();
    _respostas = List<String?>.from(widget.respostas);
  }

  @override
  Widget build(BuildContext context) {
    final pendentes = _respostas.where((r) => r == null).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Conferir respostas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.nomeAluno,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                const Text(
                  'Confira cada alternativa detetada. “Sem marcação” indica '
                  'que a leitura automática não conseguiu identificar a resposta.',
                ),
                if (pendentes > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '$pendentes questão(ões) precisam de conferência.',
                    style: const TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _respostas.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) => ListTile(
                title: Text('Questão ${index + 1}'),
                subtitle: Text(_respostas[index] == null
                    ? 'Leitura incerta / sem marcação'
                    : 'Detetada: ${_respostas[index]}'),
                trailing: DropdownButton<String?>(
                  value: _respostas[index],
                  hint: const Text('Escolher'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Em branco'),
                    ),
                    ..._opcoes.map(
                      (opcao) => DropdownMenuItem<String?>(
                        value: opcao,
                        child: Text(opcao),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _respostas[index] = value),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _respostas),
                  child: const Text('Confirmar respostas e corrigir'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
