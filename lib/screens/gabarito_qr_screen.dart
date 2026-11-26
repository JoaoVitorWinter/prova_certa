import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/prova.dart';

class ResultadoLeituraGabarito {
  final int numeroVersao;
  final List<String> gabarito;
  final List<Map<String, dynamic>> questoes;

  final bool versaoEscolhidaManualmente;

  const ResultadoLeituraGabarito({
    required this.numeroVersao,
    required this.gabarito,
    required this.questoes,
    this.versaoEscolhidaManualmente = false,
  });
}

class GabaritoQrScreen extends StatefulWidget {
  final Prova prova;
  final bool retornarResultado;

  final String? nomeAluno;

  const GabaritoQrScreen({
    super.key,
    required this.prova,
    this.retornarResultado = false,
    this.nomeAluno,
  });

  @override
  State<GabaritoQrScreen> createState() => _GabaritoQrScreenState();
}

class _GabaritoQrScreenState extends State<GabaritoQrScreen> {
  final MobileScannerController _scannerController = MobileScannerController();

  bool _qrLido = false;
  bool _processando = false;
  String? _codigoLido;
  String? _erroLeitura;
  int _numeroVersao = 1;
  // Só é preenchido depois de validar o QR da prova selecionada.
  List<String> _gabarito = [];

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  List<String>? _lerPayloadQr(String bruto) {
    try {
      final decoded = jsonDecode(bruto);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      if (decoded['app'] != 'prova_certa' ||
          decoded['tipo'] != 'gabarito_prova') {
        return null;
      }

      final provaIdQr = decoded['provaId']?.toString();
      if (provaIdQr == null || provaIdQr != widget.prova.id) {
        _erroLeitura = 'Este QR Code pertence a outra prova.';
        return null;
      }

      final versaoQr =
          (decoded['versao'] as num?)?.toInt() ??
          (decoded['numeroVersao'] as num?)?.toInt();
      if (versaoQr != null) {
        if (versaoQr < 1 || versaoQr > widget.prova.numeroVersoes) {
          _erroLeitura = 'Esta versão não pertence a esta prova.';
          return null;
        }
        _numeroVersao = versaoQr;
      }

      return _leituraDaVersao(_numeroVersao)?.gabarito;
    } on FormatException {
      return null;
    } catch (_) {
      return null;
    }
  }

  ResultadoLeituraGabarito? _leituraDaVersao(
    int numeroVersao, {
    bool manual = false,
  }) {
    final prova = widget.prova;
    final versao = (prova.versoes ?? const [])
        .where((item) => item.numero == numeroVersao)
        .firstOrNull;

    List<String> gabarito;
    List<Map<String, dynamic>> questoes;
    if (versao != null) {
      gabarito = versao.gabarito
          .map((item) => item.trim().toUpperCase())
          .toList();
      questoes = [
        for (final questao in versao.questoes)
          Map<String, dynamic>.from(questao.toMap()),
      ];
    } else if (numeroVersao == 1 && prova.gabaritoOficial != null) {
      gabarito = prova.gabaritoOficial!
          .map((item) => item.trim().toUpperCase())
          .toList();
      questoes = [
        for (final questao in prova.extrairQuestoesSnapshot())
          Map<String, dynamic>.from(questao),
      ];
    } else {
      _erroLeitura = 'Esta versão não está disponível nos dados desta prova.';
      return null;
    }

    if (gabarito.length != prova.quantidadeQuestoes ||
        gabarito.isEmpty ||
        gabarito.any((item) => !RegExp(r'^[A-E]$').hasMatch(item))) {
      _erroLeitura =
          'O gabarito da versão $numeroVersao não corresponde à quantidade '
          'de questões desta prova.';
      return null;
    }

    return ResultadoLeituraGabarito(
      numeroVersao: numeroVersao,
      gabarito: gabarito,
      questoes: questoes,
      versaoEscolhidaManualmente: manual,
    );
  }

  void _processarQr(BarcodeCapture capture) {
    if (_qrLido || _processando) return;

    for (final barcode in capture.barcodes) {
      final valor = barcode.rawValue;

      if (valor == null || valor.trim().isEmpty) continue;

      setState(() {
        _processando = true;
        _codigoLido = valor;
        _erroLeitura = null;
      });

      _scannerController.stop();

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;

        final gabarito = _lerPayloadQr(valor);

        if (gabarito == null) {
          final mensagem =
              _erroLeitura ??
              'QR Code inválido. Leia o QR gerado pelo Prova Certa para esta prova.';

          setState(() {
            _processando = false;
            _codigoLido = null;
            _erroLeitura = mensagem;
          });

          _scannerController.start();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensagem),
              backgroundColor: const Color(0xFFD32F2F),
              behavior: SnackBarBehavior.floating,
            ),
          );

          return;
        }

        setState(() {
          _gabarito = gabarito;
          _qrLido = true;
          _processando = false;
          _erroLeitura = null;
        });
        if (widget.retornarResultado) {
          Future<void>.delayed(const Duration(milliseconds: 150), () {
            if (!mounted) return;
            Navigator.pop(context, _leituraDaVersao(_numeroVersao));
          });
        }
      });

      break;
    }
  }

  void _lerNovamente() {
    setState(() {
      _qrLido = false;
      _processando = false;
      _codigoLido = null;
      _erroLeitura = null;
      _gabarito = [];
      _numeroVersao = 1;
    });
    _scannerController.start();
  }

  Future<void> _escolherVersaoManualmente() async {
    final versao = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Escolher versão da folha'),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Confira a versão impressa no cabeçalho da folha do aluno.',
              style: TextStyle(color: Color(0xFF68758A), fontSize: 12),
            ),
          ),
          for (var numero = 1; numero <= widget.prova.numeroVersoes; numero++)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, numero),
              child: Text('Versão $numero'),
            ),
        ],
      ),
    );
    if (!mounted || versao == null) return;

    final leitura = _leituraDaVersao(versao, manual: true);
    if (leitura == null) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_erroLeitura ?? 'Versão indisponível.'),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.pop(context, leitura);
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
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  children: [
                    const SizedBox(height: 50),

                    const Text(
                      'Aponte a câmera para o QR code da versão da folha:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF68758A),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 22),

                    if (widget.nomeAluno != null) ...[
                      Text(
                        'Folha de ${widget.nomeAluno}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF5146EE),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    Text(
                      '"${widget.prova.nome}"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF101827),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 28),

                    _buildScanner(),

                    const SizedBox(height: 20),

                    Text(
                      _qrLido
                          ? 'QR Code validado para esta prova!'
                          : 'Posicione o QR Code dentro da área de leitura',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _qrLido
                            ? const Color(0xFF0A9671)
                            : const Color(0xFF8A95A7),
                        fontSize: 11,
                        fontWeight: _qrLido
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),

                    if (_erroLeitura != null && !_qrLido) ...[
                      const SizedBox(height: 8),
                      Text(
                        _erroLeitura!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFD32F2F),
                          fontSize: 10,
                        ),
                      ),
                    ],

                    if (_qrLido) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Versão $_numeroVersao validada '
                        '(${_gabarito.length} questões)',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF98A2B3),
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Código: ${_codigoLido ?? '-'}',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFB4BDC9),
                          fontSize: 8,
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    const Text(
                      'Leia o QR Code da folha do aluno. Ele identifica a prova '
                      'e a versão; o gabarito vem da versão armazenada.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF929CAC),
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildButton(),
          ],
        ),
      ),
    );
  }

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
            'Versão da folha',
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

  Widget _buildScanner() {
    return Container(
      width: double.infinity,
      height: 260,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: const Color(0xFF171B29),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF5B4BEA), width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(controller: _scannerController, onDetect: _processarQr),

          IgnorePointer(
            child: CustomPaint(
              size: const Size(double.infinity, 260),
              painter: _ScannerOverlayPainter(),
            ),
          ),

          if (_processando)
            Container(
              color: Colors.black45,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Lendo QR Code...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          if (_qrLido)
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: const Color(0xBFFFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF22BE8B), width: 3),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF19A97A),
                size: 70,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(23, 12, 23, 14),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_qrLido) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: _lerNovamente,
              child: const Text('Ler outro QR Code'),
            ),
          ],
          TextButton.icon(
            onPressed: _escolherVersaoManualmente,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Não conseguiu ler? Escolher a versão manualmente'),
          ),
        ],
      ),
    );
  }
}

class _GabaritoManual {
  final int numeroVersao;
  final List<String> gabarito;
  final List<Map<String, dynamic>> questoes;

  const _GabaritoManual({
    required this.numeroVersao,
    required this.gabarito,
    required this.questoes,
  });
}

class _GabaritoManualScreen extends StatefulWidget {
  final Prova prova;

  const _GabaritoManualScreen({required this.prova});

  @override
  State<_GabaritoManualScreen> createState() => _GabaritoManualScreenState();
}

class _GabaritoManualScreenState extends State<_GabaritoManualScreen> {
  late int _versao;
  late List<String?> _respostas;

  @override
  void initState() {
    super.initState();
    _versao = 1;
    _respostas = List<String?>.filled(widget.prova.quantidadeQuestoes, null);
  }

  List<String> _gabaritoDaVersao(int versao) {
    for (final item in widget.prova.versoes ?? const []) {
      if (item.numero == versao && item.gabarito.isNotEmpty) {
        return List<String>.from(item.gabarito);
      }
    }
    final oficial = widget.prova.gabaritoOficial;
    if (oficial != null && oficial.length == widget.prova.quantidadeQuestoes) {
      return List<String>.from(oficial);
    }
    return List<String>.filled(widget.prova.quantidadeQuestoes, '');
  }

  void _carregarVersao(int versao) {
    setState(() {
      _versao = versao;
      _respostas = List<String?>.filled(widget.prova.quantidadeQuestoes, null);
    });
  }

  void _confirmar() {
    if (_respostas.any((resposta) => resposta == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe as respostas marcadas pelo aluno.'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      _GabaritoManual(
        numeroVersao: _versao,
        gabarito: _gabaritoDaVersao(_versao),
        questoes: _questoesDaVersao(_versao),
      ),
    );
  }

  List<Map<String, dynamic>> _questoesDaVersao(int versao) {
    for (final item in widget.prova.versoes ?? const []) {
      if (item.numero == versao) {
        final snapshot = <Map<String, dynamic>>[];
        for (final questao in item.questoes) {
          snapshot.add(Map<String, dynamic>.from(questao.toMap()));
        }
        return snapshot;
      }
    }
    final fallback = <Map<String, dynamic>>[];
    for (final questao in widget.prova.extrairQuestoesSnapshot()) {
      fallback.add(Map<String, dynamic>.from(questao));
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Digitar versão e respostas')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<int>(
                initialValue: _versao,
                decoration: const InputDecoration(
                  labelText: 'Versão da prova',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(
                  widget.prova.numeroVersoes,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('Versão ${index + 1}'),
                  ),
                ),
                onChanged: (valor) {
                  if (valor != null) _carregarVersao(valor);
                },
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _respostas.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) => ListTile(
                  title: Text('Questão ${index + 1}'),
                  trailing: DropdownButton<String?>(
                    value: _respostas[index],
                    hint: const Text('Escolher'),
                    items: ['A', 'B', 'C', 'D', 'E']
                        .map(
                          (letra) => DropdownMenuItem(
                            value: letra,
                            child: Text(letra),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) {
                      setState(() => _respostas[index] = valor);
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmar,
                  child: const Text('Confirmar respostas'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5C4DEB)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const double boxSize = 160;
    final double left = (size.width - boxSize) / 2;
    final double top = (size.height - boxSize) / 2;
    const double corner = 22;

    // Canto superior esquerdo
    canvas.drawLine(Offset(left, top + corner), Offset(left, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left + corner, top), paint);

    // Canto superior direito
    canvas.drawLine(
      Offset(left + boxSize - corner, top),
      Offset(left + boxSize, top),
      paint,
    );
    canvas.drawLine(
      Offset(left + boxSize, top),
      Offset(left + boxSize, top + corner),
      paint,
    );

    // Canto inferior esquerdo
    canvas.drawLine(
      Offset(left, top + boxSize - corner),
      Offset(left, top + boxSize),
      paint,
    );
    canvas.drawLine(
      Offset(left, top + boxSize),
      Offset(left + corner, top + boxSize),
      paint,
    );

    // Canto inferior direito
    canvas.drawLine(
      Offset(left + boxSize - corner, top + boxSize),
      Offset(left + boxSize, top + boxSize),
      paint,
    );
    canvas.drawLine(
      Offset(left + boxSize, top + boxSize),
      Offset(left + boxSize, top + boxSize - corner),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
