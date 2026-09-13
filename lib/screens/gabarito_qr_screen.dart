import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'folhas_screen.dart';

import '../models/prova.dart';

class GabaritoQrScreen extends StatefulWidget {
  final Prova prova;

  const GabaritoQrScreen({
    super.key,
    required this.prova,
  });

  @override
  State<GabaritoQrScreen> createState() => _GabaritoQrScreenState();
}

class _GabaritoQrScreenState extends State<GabaritoQrScreen> {
  final MobileScannerController _scannerController =
      MobileScannerController();

  bool _qrLido = false;
  bool _processando = false;
  String? _codigoLido;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _processarQr(BarcodeCapture capture) {
    if (_qrLido || _processando) return;

    for (final barcode in capture.barcodes) {
      final valor = barcode.rawValue;

      if (valor == null || valor.trim().isEmpty) continue;

      setState(() {
        _processando = true;
        _codigoLido = valor;
      });

      _scannerController.stop();

      // Pequeno atraso para dar sensação de processamento.
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;

        setState(() {
          _qrLido = true;
          _processando = false;
        });
      });

      break;
    }
  }

  void _avancar() {
  if (!_qrLido) return;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => FolhasScreen(
        prova: widget.prova,
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
                          ? 'QR Code reconhecido com sucesso!'
                          : 'Posicione o QR Code dentro da área de leitura',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _qrLido
                            ? const Color(0xFF0A9671)
                            : const Color(0xFF8A95A7),
                        fontSize: 11,
                        fontWeight:
                            _qrLido ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),

                    if (_codigoLido != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Código: $_codigoLido',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF98A2B3),
                          fontSize: 9,
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    const Text(
                      'O gabarito com QR code é gerado automaticamente ao criar a prova.',
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
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE4E9F1),
          ),
        ),
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
        border: Border.all(
          color: const Color(0xFF5B4BEA),
          width: 1.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _processarQr,
          ),

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
                border: Border.all(
                  color: const Color(0xFF22BE8B),
                  width: 3,
                ),
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
      child: SizedBox(
        height: 41,
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
          child: Text(
            _qrLido ? 'QR lido — avançar' : 'Aguardando QR Code...',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
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
    canvas.drawLine(
      Offset(left, top + corner),
      Offset(left, top),
      paint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left + corner, top),
      paint,
    );

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