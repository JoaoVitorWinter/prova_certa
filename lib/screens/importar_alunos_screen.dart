import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/importacao_alunos_service.dart';
import '../services/turma_service.dart';

class ImportarAlunosModal extends StatefulWidget {
  final String turmaId;
  final TurmaService? turmaService;
  final Uint8List? initialBytes;
  final String? initialFileName;

  const ImportarAlunosModal({
    super.key,
    required this.turmaId,
    this.turmaService,
    this.initialBytes,
    this.initialFileName,
  });

  @override
  State<ImportarAlunosModal> createState() => _ImportarAlunosModalState();
}

class _ImportarAlunosModalState extends State<ImportarAlunosModal> {
  String? arquivoSelecionado;
  bool _analisando = false;
  bool _salvando = false;
  ResultadoAnaliseImportacao? _resultado;
  late final TurmaService _turmaService;

  @override
  void initState() {
    super.initState();
    _turmaService = widget.turmaService ?? TurmaService();

    if (widget.initialBytes != null && widget.initialFileName != null) {
      arquivoSelecionado = widget.initialFileName;
      _processarBytes(widget.initialBytes!, widget.initialFileName!);
    }
  }

  Future<void> _processarBytes(Uint8List bytes, String nome) async {
    setState(() {
      _analisando = true;
      _resultado = null;
    });

    try {
      final existentes =
          await _turmaService.listarAlunos(turmaId: widget.turmaId);
      final rasExistentes = existentes.map((a) => a.ra.trim()).toSet();

      final analise = await ImportacaoAlunosService.analisarArquivo(
        bytes: bytes,
        nomeArquivo: nome,
        rasExistentesNaTurma: rasExistentes,
      );

      if (mounted) {
        setState(() {
          _analisando = false;
          _resultado = analise;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analisando = false;
          _resultado =
              ResultadoAnaliseImportacao.comErro('Falha ao processar arquivo: $e');
        });
      }
    }
  }

  Future<void> selecionarArquivo() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
      );

      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        if (mounted) {
          setState(() {
            arquivoSelecionado = file.name;
            _resultado = ResultadoAnaliseImportacao.comErro(
              'O arquivo selecionado está vazio.',
            );
          });
        }
        return;
      }

      setState(() {
        arquivoSelecionado = file.name;
      });

      await _processarBytes(bytes, file.name);
    } catch (e) {
      if (mounted) {
        setState(() {
          _resultado =
              ResultadoAnaliseImportacao.comErro('Erro ao selecionar arquivo: $e');
        });
      }
    }
  }

  Future<void> _confirmarImportacao() async {
    if (_salvando || _resultado == null || !_resultado!.temAlunosParaImportar) {
      return;
    }

    setState(() => _salvando = true);

    try {
      final total = await _turmaService.importarAlunosLote(
        turmaId: widget.turmaId,
        alunos: _resultado!.alunosValidos,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$total alunos importados com sucesso!',
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar no Firestore: $e'),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Importar alunos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Selecione uma planilha Excel (.xlsx) ou CSV com as colunas RA e Nome.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: (_salvando || _analisando) ? null : selecionarArquivo,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(
                  arquivoSelecionado == null
                      ? 'Selecionar arquivo'
                      : 'Trocar arquivo',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6545E8),
                  side: const BorderSide(color: Color(0xFF8B7CF6)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              if (_analisando) ...[
                const SizedBox(height: 20),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: Color(0xFF6545E8)),
                        SizedBox(height: 10),
                        Text(
                          'Analisando dados do arquivo...',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (arquivoSelecionado != null && !_analisando) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        color: Color(0xFF6545E8),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          arquivoSelecionado!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF00A56A),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
              if (_resultado != null && !_analisando) ...[
                const SizedBox(height: 16),
                if (_resultado!.temErroGeral)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFC62828),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _resultado!.erroGeral!,
                            style: const TextStyle(
                              color: Color(0xFFC62828),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Grid de resumo de validação
                  Row(
                    children: [
                      Expanded(
                        child: _StatBadge(
                          titulo: 'Válidos',
                          valor: '${_resultado!.totalValidos}',
                          cor: const Color(0xFF00A56A),
                          fundo: const Color(0xFFD5F7E8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatBadge(
                          titulo: 'Já na turma',
                          valor: '${_resultado!.totalDuplicadosTurma}',
                          cor: const Color(0xFFE8790C),
                          fundo: const Color(0xFFFFECCC),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatBadge(
                          titulo: 'Duplicados',
                          valor: '${_resultado!.totalDuplicadosArquivo}',
                          cor: const Color(0xFF7C3AED),
                          fundo: const Color(0xFFF3E8FF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatBadge(
                          titulo: 'Inválidos',
                          valor: '${_resultado!.totalInvalidos}',
                          cor: const Color(0xFFDC2626),
                          fundo: const Color(0xFFFEE2E2),
                        ),
                      ),
                    ],
                  ),
                  if (_resultado!.avisos.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _resultado!.avisos.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          return Text(
                            '• ${_resultado!.avisos[index]}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF92400E),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: (_salvando ||
                          _analisando ||
                          _resultado == null ||
                          !_resultado!.temAlunosParaImportar)
                      ? null
                      : _confirmarImportacao,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6545E8),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD8D4F8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _salvando
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _resultado == null
                              ? 'Concluir'
                              : (_resultado!.temAlunosParaImportar
                                  ? 'Importar ${_resultado!.totalValidos} alunos'
                                  : 'Nenhum aluno a importar'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color cor;
  final Color fundo;

  const _StatBadge({
    required this.titulo,
    required this.valor,
    required this.cor,
    required this.fundo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            valor,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: cor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}