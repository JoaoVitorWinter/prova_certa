import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';

import '../models/prova.dart';
import '../services/geracao_pdf_prova_service.dart';

class VersoesProvaScreen extends StatefulWidget {
  final Prova prova;

  const VersoesProvaScreen({super.key, required this.prova});

  @override
  State<VersoesProvaScreen> createState() => _VersoesProvaScreenState();
}

class _VersoesProvaScreenState extends State<VersoesProvaScreen> {
  final _pdfService = GeracaoPdfProvaService();
  final _pageController = PageController();
  bool _processando = false;
  Uint8List? _pdfPreview;
  int? _previewVersion;
  int _paginaAtual = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get _quantidadeVersoes => widget.prova.numeroVersoes.clamp(1, 4);

  String _nomeBase() {
    final nome = widget.prova.nome
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return 'prova_$nome';
  }

  Future<void> _baixarVersao(int numero) async {
    await _salvarArquivos(
      () async => [
        (
          bytes: await _pdfService.gerar(
            prova: widget.prova,
            numeroVersao: numero,
          ),
          nome: '${_nomeBase()}_v$numero.pdf',
        ),
      ],
      'Versão $numero',
    );
  }

  Future<void> _baixarTodas() async {
    final formato = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Baixar todas as versões',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Escolha como deseja receber os arquivos.'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Um único PDF'),
              subtitle: Text('As $_quantidadeVersoes versões no mesmo arquivo'),
              onTap: () => Navigator.pop(context, 'unico'),
            ),
            ListTile(
              leading: const Icon(Icons.file_copy_outlined),
              title: const Text('PDFs separados'),
              subtitle: const Text('Um arquivo para cada versão'),
              onTap: () => Navigator.pop(context, 'separados'),
            ),
          ],
        ),
      ),
    );
    if (formato == null) return;

    await _salvarArquivos(() async {
      if (formato == 'unico') {
        return [
          (
            bytes: await _pdfService.gerarTodas(prova: widget.prova),
            nome: '${_nomeBase()}_todas_as_versoes.pdf',
          ),
        ];
      }
      final arquivos = await _pdfService.gerarTodasSeparadas(
        prova: widget.prova,
      );
      return [
        for (var i = 0; i < arquivos.length; i++)
          (bytes: arquivos[i], nome: '${_nomeBase()}_v${i + 1}.pdf'),
      ];
    }, 'Todas as versões');
  }

  Future<void> _salvarArquivos(
    Future<List<({Uint8List bytes, String nome})>> Function() gerar,
    String descricao,
  ) async {
    setState(() => _processando = true);
    try {
      final arquivos = await gerar();
      for (final arquivo in arquivos) {
        await FilePicker.saveFile(
          fileName: arquivo.nome,
          bytes: arquivo.bytes,
          mimeType: 'application/pdf',
          dialogTitle: descricao,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível gerar o PDF: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _prepararPreview(int numero) async {
    setState(() {
      _processando = true;
      _previewVersion = numero;
      _pdfPreview = null;
    });
    try {
      final bytes = await _pdfService.gerar(
        prova: widget.prova,
        numeroVersao: numero,
      );
      if (mounted) setState(() => _pdfPreview = bytes);
    } catch (e) {
      if (mounted) {
        setState(() => _previewVersion = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível gerar a prévia: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final versoes = widget.prova.versoes ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Versões da prova'),
        actions: [
          IconButton(
            tooltip: 'Baixar todas',
            onPressed: _processando ? null : _baixarTodas,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_processando) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${widget.prova.nome}\n$_quantidadeVersoes '
                '${_quantidadeVersoes == 1 ? 'versão disponível' : 'versões disponíveis'}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (pagina) {
                setState(() {
                  _paginaAtual = pagina;
                  _pdfPreview = null;
                  _previewVersion = null;
                });
              },
              itemCount: _quantidadeVersoes,
              itemBuilder: (context, index) {
                final numero = index + 1;
                final correspondentes = versoes
                    .where((item) => item.numero == numero)
                    .toList();
                final versao = correspondentes.isEmpty
                    ? null
                    : correspondentes.first;
                final questoes = versao?.questoes ?? const [];
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Versão $numero de $_quantidadeVersoes',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_previewVersion == numero && _pdfPreview != null)
                            Expanded(
                              child: PdfPreview(
                                build: (_) async => _pdfPreview!,
                                allowPrinting: false,
                                allowSharing: false,
                                canChangeOrientation: false,
                                canChangePageFormat: false,
                                canDebug: false,
                                pdfFileName: '${_nomeBase()}_v$numero.pdf',
                              ),
                            )
                          else ...[
                            Text(
                              versao == null
                                  ? 'Versão original'
                                  : 'Questões e alternativas configuradas para esta versão.',
                            ),
                            const SizedBox(height: 16),
                            if (questoes.isNotEmpty)
                              Expanded(
                                child: ListView.builder(
                                  itemCount: questoes.length,
                                  itemBuilder: (context, questaoIndex) =>
                                      ListTile(
                                        dense: true,
                                        leading: Text('${questaoIndex + 1}'),
                                        title: Text(
                                          questoes[questaoIndex].enunciado,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                ),
                              )
                            else
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    'A versão original usará as questões salvas na prova.',
                                  ),
                                ),
                              ),
                          ],
                          if (_previewVersion != numero)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: OutlinedButton.icon(
                                onPressed: _processando
                                    ? null
                                    : () => _prepararPreview(numero),
                                icon: const Icon(Icons.preview_outlined),
                                label: const Text('Visualizar PDF'),
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _processando
                                  ? null
                                  : () => _baixarVersao(numero),
                              icon: const Icon(Icons.download_outlined),
                              label: const Text('Baixar esta versão'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _paginaAtual == 0
                            ? null
                            : () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              ),
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Anterior'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _paginaAtual >= _quantidadeVersoes - 1
                            ? null
                            : () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              ),
                        icon: const Icon(Icons.chevron_right),
                        label: const Text('Próxima'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _processando ? null : _baixarTodas,
                    icon: const Icon(Icons.download_for_offline_outlined),
                    label: const Text('Baixar todas as versões'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
