import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/prova.dart';
import 'folhas_screen.dart';

class GabaritoQrScreen extends StatefulWidget {
  final Prova prova;

  const GabaritoQrScreen({super.key, required this.prova});

  @override
  State<GabaritoQrScreen> createState() => _GabaritoQrScreenState();
}

class _GabaritoQrScreenState extends State<GabaritoQrScreen> {
  final MobileScannerController _scannerController = MobileScannerController();

  bool _qrLido = false;
  bool _processando = false;
  String? _codigoLido;
  String? _erroLeitura;

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

      final rawGabarito = decoded['gabarito'];
      if (rawGabarito is! List) {
        return null;
      }

      final gabarito = rawGabarito
          .map((item) => item.toString().trim().toUpperCase())
          .toList();

      if (gabarito.length != widget.prova.quantidadeQuestoes ||
          gabarito.isEmpty ||
          gabarito.any((item) => !RegExp(r'^[A-E]$').hasMatch(item))) {
        _erroLeitura =
            'O gabarito do QR Code não corresponde à quantidade de questões desta prova.';
        return null;
      }

      return gabarito;
    } on FormatException {
      return null;
    } catch (_) {
      return null;
    }
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
          final mensagem = _erroLeitura ??
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
    });
    _scannerController.start();
  }

  void _avancar() {
    if (!_qrLido ||
        _gabarito.length != widget.prova.quantidadeQuestoes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leia primeiro um QR Code válido desta prova.'),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FolhasScreen(prova: widget.prova, gabarito: List<String>.from(_gabarito)),
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
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  children: [
                    const SizedBox(height: 50),

                    const Text(
                      'Aponte a câmera para o QR code do gabarito da prova:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF68758A),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 22),

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
                        'Gabarito lido: ${_gabarito.join(' · ')} '
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
                      'Leia o QR Code gerado ao criar esta prova. O código deve '
                      'corresponder à prova selecionada e à quantidade de questões.',
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
            'Passo 1: Gabarito',
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
          SizedBox(
            height: 41,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _qrLido ? _avancar : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5647E8),
                disabledBackgroundColor: const Color(0xFFD7D9E2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continuar para leitura das folhas',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (_qrLido) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: _lerNovamente,
              child: const Text('Ler outro QR Code'),
            ),
          ],
        ],
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
