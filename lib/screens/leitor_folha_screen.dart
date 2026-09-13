import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../models/prova.dart';

class LeitorFolhaScreen extends StatefulWidget {
  final Prova prova;
  final int numeroFolha;

  // Gabarito vindo do QR Code. Define tambem quantas questoes ler.
  final List<String> gabarito;

  const LeitorFolhaScreen({
    super.key,
    required this.prova,
    required this.numeroFolha,
    required this.gabarito,
  });

  @override
  State<LeitorFolhaScreen> createState() => _LeitorFolhaScreenState();
}

class _LeitorFolhaScreenState extends State<LeitorFolhaScreen> {
  CameraController? _cameraController;

  bool _inicializando = true;
  bool _lendo = false;
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
        if (!mounted) return;

        setState(() {
          _erro = 'Nenhuma câmera encontrada no dispositivo.';
          _inicializando = false;
        });

        return;
      }

      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
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
        _cameraController = controller;
        _inicializando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível iniciar a câmera.';
        _inicializando = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // ============================================================
  // CAPTURA E LEITURA DA FOLHA
  // ============================================================

  Future<void> _lerFolha() async {
    final camera = _cameraController;

    if (camera == null ||
        !camera.value.isInitialized ||
        _lendo) {
      return;
    }

    setState(() {
      _lendo = true;
    });

    try {
      // FOTO REAL DA FOLHA
      final foto = await camera.takePicture();

      if (!mounted) return;

      // PEGA AS RESPOSTAS A PARTIR DA FOTO
      final respostas = await _detectarRespostas(foto.path);

      if (!mounted) return;

      if (respostas.isEmpty) {
        setState(() {
          _lendo = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível identificar as respostas.',
            ),
          ),
        );

        return;
      }

      // Gabarito real, lido do QR Code no passo 1.
      final gabarito = widget.gabarito;

      int acertos = 0;

      final totalComparar = math.min(
        respostas.length,
        gabarito.length,
      );

      for (int i = 0; i < totalComparar; i++) {
        if (respostas[i] == gabarito[i]) {
          acertos++;
        }
      }

      final resultado = <String, dynamic>{
        'aluno': 'Aluno ${widget.numeroFolha}',
        'matricula': '202600${widget.numeroFolha}',
        'respostas': respostas,
        'gabarito': gabarito,
        'acertos': acertos,
        'total': gabarito.length,
        'numeroFolha': widget.numeroFolha,
      };

      // DEVOLVE O RESULTADO PARA A FolhasScreen
      Navigator.pop(
        context,
        resultado,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _lendo = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao analisar a folha: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // DETECTOR DE RESPOSTAS
  // ============================================================

  Future<List<String>> _detectarRespostas(
    String caminhoImagem,
  ) async {
    final arquivo = File(caminhoImagem);

    if (!arquivo.existsSync()) {
      return [];
    }

    final bytes = await arquivo.readAsBytes();

    final imagemOriginal = img.decodeImage(bytes);

    if (imagemOriginal == null) {
      return [];
    }

    final imagem = img.bakeOrientation(
      imagemOriginal,
    );

    final largura = imagem.width;
    final altura = imagem.height;

    // ----------------------------------------------------------
    // REGIÃO DAS RESPOSTAS
    //
    // Primeiro teste baseado na folha que você enviou.
    // ----------------------------------------------------------

    final double inicioX = largura * 0.20;
    final double fimX = largura * 0.63;

    final double inicioY = altura * 0.27;
    final double fimY = altura * 0.56;

    const alternativas = <String>[
      'A',
      'B',
      'C',
      'D',
      'E',
    ];

    final resultados = <String>[];

    // A quantidade de questoes vem do gabarito lido no QR Code.
    final quantidadeQuestoes = widget.gabarito.length;

    if (quantidadeQuestoes == 0) {
      return [];
    }

    for (
      int questao = 0;
      questao < quantidadeQuestoes;
      questao++
    ) {
      final progressoY =
          quantidadeQuestoes == 1
              ? 0.0
              : questao / (quantidadeQuestoes - 1);

      final centroY =
          inicioY +
          ((fimY - inicioY) * progressoY);

      String melhorAlternativa = '?';
      double maiorDensidade = 0;

      for (
        int alternativa = 0;
        alternativa < alternativas.length;
        alternativa++
      ) {
        final progressoX =
            alternativa / (alternativas.length - 1);

        final centroX =
            inicioX +
            ((fimX - inicioX) * progressoX);

        final densidade = _densidadeEscura(
          imagem,
          centroX,
          centroY,
          largura,
          altura,
        );

        if (densidade > maiorDensidade) {
          maiorDensidade = densidade;
          melhorAlternativa =
              alternativas[alternativa];
        }
      }

      // Se nenhuma região tiver tinta suficiente,
      // marca como não identificada.
      if (maiorDensidade < 0.05) {
        resultados.add('?');
      } else {
        resultados.add(melhorAlternativa);
      }
    }

    return resultados;
  }

  // ============================================================
  // MEDIÇÃO DE PIXELS ESCUROS
  // ============================================================

  double _densidadeEscura(
    img.Image imagem,
    double centroX,
    double centroY,
    int largura,
    int altura,
  ) {
    final raioX = math.max(
      8,
      (largura * 0.018).round(),
    );

    final raioY = math.max(
      8,
      (altura * 0.014).round(),
    );

    final esquerda = math.max(
      0,
      centroX.round() - raioX,
    );

    final direita = math.min(
      largura - 1,
      centroX.round() + raioX,
    );

    final topo = math.max(
      0,
      centroY.round() - raioY,
    );

    final baixo = math.min(
      altura - 1,
      centroY.round() + raioY,
    );

    int pixelsEscuros = 0;
    int pixelsTotais = 0;

    for (int y = topo; y <= baixo; y++) {
      for (int x = esquerda; x <= direita; x++) {
        final pixel = imagem.getPixel(x, y);

        final luminosidade =
            (pixel.r +
                pixel.g +
                pixel.b) /
            3;

        if (luminosidade < 110) {
          pixelsEscuros++;
        }

        pixelsTotais++;
      }
    }

    if (pixelsTotais == 0) {
      return 0;
    }

    return pixelsEscuros / pixelsTotais;
  }

  // ============================================================
  // INTERFACE
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
              child: _buildCameraArea(),
            ),
            _buildBottom(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 57,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
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
                color: Color(0xFF5146E8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Ler folha ${widget.numeroFolha}',
                  style: const TextStyle(
                    color: Color(0xFF101827),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.prova.nome,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8B96A8),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraArea() {
    if (_inicializando) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF5747E8),
        ),
      );
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Color(0xFF6D788A),
                size: 55,
              ),
              const SizedBox(height: 14),
              Text(
                _erro!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF475467),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _cameraController!;

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: CameraPreview(controller),
        ),

        Positioned.fill(
          child: Container(
            color: Colors.black26,
          ),
        ),

        Container(
          width: 285,
          height: 390,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF6755EE),
              width: 3,
            ),
          ),
        ),

        Positioned(
          top: 30,
          left: 20,
          right: 20,
          child: Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: const Text(
              'Enquadre toda a folha dentro da área',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        if (_lendo)
          Container(
            color: Colors.black54,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Colors.white,
                ),
                SizedBox(height: 14),
                Text(
                  'Analisando folha...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBottom() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        16,
      ),
      color: Colors.white,
      child: SizedBox(
        height: 44,
        child: ElevatedButton.icon(
          onPressed:
              _lendo ? null : _lerFolha,
          icon: const Icon(
            Icons.document_scanner_outlined,
            size: 18,
          ),
          label: Text(
            _lendo
                ? 'Analisando...'
                : 'Ler folha',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                const Color(0xFF5747E8),
            disabledBackgroundColor:
                const Color(0xFFD8DAE3),
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
