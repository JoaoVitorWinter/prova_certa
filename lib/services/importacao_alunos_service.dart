import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:xml/xml.dart';

import '../models/aluno.dart';

class ItemAnaliseImportacao {
  final int linha;
  final String nome;
  final String ra;
  final bool valido;
  final bool duplicadoArquivo;
  final bool duplicadoTurma;
  final String? motivo;

  ItemAnaliseImportacao({
    required this.linha,
    required this.nome,
    required this.ra,
    required this.valido,
    this.duplicadoArquivo = false,
    this.duplicadoTurma = false,
    this.motivo,
  });

  bool get podeSalvar => valido && !duplicadoArquivo && !duplicadoTurma;
}

class ResultadoAnaliseImportacao {
  final List<ItemAnaliseImportacao> itens;
  final List<Aluno> alunosValidos;
  final int totalValidos;
  final int totalInvalidos;
  final int totalDuplicadosArquivo;
  final int totalDuplicadosTurma;
  final List<String> avisos;
  final String? erroGeral;

  ResultadoAnaliseImportacao({
    required this.itens,
    required this.alunosValidos,
    required this.totalValidos,
    required this.totalInvalidos,
    required this.totalDuplicadosArquivo,
    required this.totalDuplicadosTurma,
    required this.avisos,
    this.erroGeral,
  });

  bool get temErroGeral => erroGeral != null;
  bool get temAlunosParaImportar => totalValidos > 0;

  factory ResultadoAnaliseImportacao.comErro(String mensagem) {
    return ResultadoAnaliseImportacao(
      itens: const [],
      alunosValidos: const [],
      totalValidos: 0,
      totalInvalidos: 0,
      totalDuplicadosArquivo: 0,
      totalDuplicadosTurma: 0,
      avisos: [mensagem],
      erroGeral: mensagem,
    );
  }
}

class ImportacaoAlunosService {
  /// Analisa o arquivo (CSV ou XLSX) e retorna o resumo para pré-visualização
  static Future<ResultadoAnaliseImportacao> analisarArquivo({
    required Uint8List bytes,
    required String nomeArquivo,
    required Set<String> rasExistentesNaTurma,
  }) async {
    if (bytes.isEmpty) {
      return ResultadoAnaliseImportacao.comErro(
        'O arquivo selecionado está vazio.',
      );
    }

    final extensao = nomeArquivo.split('.').last.toLowerCase();
    List<List<String>> linhasMatriz;

    try {
      if (extensao == 'xlsx') {
        linhasMatriz = _extrairLinhasXlsx(bytes);
      } else if (extensao == 'csv') {
        linhasMatriz = _extrairLinhasCsv(bytes);
      } else {
        return ResultadoAnaliseImportacao.comErro(
          'Formato não suportado. Selecione um arquivo .csv ou .xlsx.',
        );
      }
    } catch (e) {
      return ResultadoAnaliseImportacao.comErro(
        'Erro ao ler o arquivo: Formato corrompido ou inválido ($e).',
      );
    }

    return _processarLinhasMatriz(linhasMatriz, rasExistentesNaTurma);
  }

  /// Extrai linhas de arquivos CSV suportando delimitadores ',' e ';'
  static List<List<String>> _extrairLinhasCsv(Uint8List bytes) {
    String conteudo;
    try {
      conteudo = utf8.decode(bytes);
    } catch (_) {
      conteudo = latin1.decode(bytes);
    }

    if (conteudo.trim().isEmpty) {
      return [];
    }

    // Identifica delimitador pela primeira linha não vazia
    final primeiraLinha = conteudo.split('\n').firstWhere(
          (l) => l.trim().isNotEmpty,
          orElse: () => '',
        );

    final qtdPontoVirgula = ';'.allMatches(primeiraLinha).length;
    final qtdVirgula = ','.allMatches(primeiraLinha).length;
    final delimitador =
        (qtdPontoVirgula >= qtdVirgula && qtdPontoVirgula > 0) ? ';' : ',';

    final conversor = CsvDecoder(
      fieldDelimiter: delimitador,
      dynamicTyping: false,
    );

    final resultadoDinamico = conversor.convert(conteudo);

    return resultadoDinamico.map((linha) {
      return linha.map((celula) => celula?.toString() ?? '').toList();
    }).toList();
  }

  /// Extrai linhas da primeira planilha do arquivo XLSX usando ZipDecoder e XmlDocument
  static List<List<String>> _extrairLinhasXlsx(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);

    // 1. Carrega tabela de strings compartilhadas (sharedStrings.xml), se existir
    final sharedStrings = <String>[];
    final sharedStringsFile = archive.findFile('xl/sharedStrings.xml');
    if (sharedStringsFile != null) {
      final xmlDoc = XmlDocument.parse(utf8.decode(sharedStringsFile.content));
      for (final si in xmlDoc.findAllElements('si')) {
        final texto = si.findAllElements('t').map((e) => e.innerText).join();
        sharedStrings.add(texto);
      }
    }

    // 2. Localiza a primeira planilha com dados
    ArchiveFile? sheetFile = archive.findFile('xl/worksheets/sheet1.xml');
    if (sheetFile == null) {
      for (final file in archive.files) {
        if (file.name.startsWith('xl/worksheets/') &&
            file.name.endsWith('.xml')) {
          sheetFile = file;
          break;
        }
      }
    }

    if (sheetFile == null) {
      return [];
    }

    final sheetXml = XmlDocument.parse(utf8.decode(sheetFile.content));
    final linhas = <List<String>>[];

    for (final row in sheetXml.findAllElements('row')) {
      final celulasDaLinha = <int, String>{};
      int maxCol = -1;

      for (final c in row.findElements('c')) {
        final ref = c.getAttribute('r') ?? '';
        final tipo = c.getAttribute('t') ?? '';
        final colIndex = _colunaRefParaIndice(ref);
        if (colIndex > maxCol) maxCol = colIndex;

        String valor = '';
        if (tipo == 's') {
          final vElement = c.findElements('v').firstOrNull;
          final idx = int.tryParse(vElement?.innerText ?? '') ?? -1;
          if (idx >= 0 && idx < sharedStrings.length) {
            valor = sharedStrings[idx];
          }
        } else if (tipo == 'inlineStr') {
          valor = c.findAllElements('t').map((e) => e.innerText).join();
        } else {
          final vElement = c.findElements('v').firstOrNull;
          valor = vElement?.innerText ?? '';
          if (valor.endsWith('.0')) {
            valor = valor.substring(0, valor.length - 2);
          }
        }

        celulasDaLinha[colIndex] = valor;
      }

      if (maxCol >= 0) {
        final linhaPreenchida = <String>[];
        for (int i = 0; i <= maxCol; i++) {
          linhaPreenchida.add(celulasDaLinha[i] ?? '');
        }
        linhas.add(linhaPreenchida);
      }
    }

    return linhas;
  }

  /// Converte referência de coluna Excel (Ex: "A", "B", "AA") para índice 0-based
  static int _colunaRefParaIndice(String ref) {
    final letras = ref.replaceAll(RegExp(r'[0-9]'), '').toUpperCase();
    if (letras.isEmpty) return 0;
    int indice = 0;
    for (int i = 0; i < letras.length; i++) {
      indice = indice * 26 + (letras.codeUnitAt(i) - 64);
    }
    return indice - 1;
  }

  /// Processa a matriz de linhas, valida cabeçalhos, RA e Nome, e analisa duplicidades
  static ResultadoAnaliseImportacao _processarLinhasMatriz(
    List<List<String>> matriz,
    Set<String> rasExistentesNaTurma,
  ) {
    if (matriz.isEmpty) {
      return ResultadoAnaliseImportacao.comErro('O arquivo não contém dados.');
    }

    // 1. Identifica o cabeçalho na primeira linha não vazia
    int cabecalhoIdx = -1;
    int raColIdx = -1;
    int nomeColIdx = -1;

    for (int i = 0; i < matriz.length; i++) {
      final linha = matriz[i];
      if (linha.every((celula) => celula.trim().isEmpty)) continue;

      for (int c = 0; c < linha.length; c++) {
        final valor = linha[c].trim().toLowerCase();
        if (_ehColunaRa(valor)) {
          raColIdx = c;
        } else if (_ehColunaNome(valor)) {
          nomeColIdx = c;
        }
      }

      if (raColIdx != -1 || nomeColIdx != -1) {
        cabecalhoIdx = i;
        break;
      }
    }

    if (cabecalhoIdx == -1 || raColIdx == -1 || nomeColIdx == -1) {
      return ResultadoAnaliseImportacao.comErro(
        'Arquivo inválido: As colunas obrigatórias "RA" e "Nome" não foram encontradas.',
      );
    }

    final itens = <ItemAnaliseImportacao>[];
    final alunosValidos = <Aluno>[];
    final avisos = <String>[];
    final rasNoArquivo = <String>{};

    int totalValidos = 0;
    int totalInvalidos = 0;
    int totalDuplicadosArquivo = 0;
    int totalDuplicadosTurma = 0;

    // 2. Itera sobre as linhas de dados a partir do cabeçalho
    for (int i = cabecalhoIdx + 1; i < matriz.length; i++) {
      final linha = matriz[i];
      final numeroLinha = i + 1;

      if (linha.every((c) => c.trim().isEmpty)) {
        continue; // Ignora linhas em branco
      }

      final rawNome = linha.length > nomeColIdx ? linha[nomeColIdx].trim() : '';
      final rawRa = linha.length > raColIdx ? linha[raColIdx].trim() : '';

      // Validação de preenchimento obrigatório
      if (rawNome.isEmpty || rawRa.isEmpty) {
        final motivo = rawNome.isEmpty && rawRa.isEmpty
            ? 'Nome e RA em branco'
            : (rawNome.isEmpty ? 'Nome em branco' : 'RA em branco');

        itens.add(
          ItemAnaliseImportacao(
            linha: numeroLinha,
            nome: rawNome,
            ra: rawRa,
            valido: false,
            motivo: motivo,
          ),
        );
        avisos.add('Linha $numeroLinha: $motivo');
        totalInvalidos++;
        continue;
      }

      // Validação de duplicação dentro do próprio arquivo
      if (rasNoArquivo.contains(rawRa)) {
        itens.add(
          ItemAnaliseImportacao(
            linha: numeroLinha,
            nome: rawNome,
            ra: rawRa,
            valido: true,
            duplicadoArquivo: true,
            motivo: 'RA "$rawRa" duplicado no arquivo',
          ),
        );
        avisos.add('Linha $numeroLinha: RA "$rawRa" duplicado no arquivo.');
        totalDuplicadosArquivo++;
        continue;
      }

      rasNoArquivo.add(rawRa);

      // Validação de duplicação com alunos já existentes na turma
      if (rasExistentesNaTurma.contains(rawRa)) {
        itens.add(
          ItemAnaliseImportacao(
            linha: numeroLinha,
            nome: rawNome,
            ra: rawRa,
            valido: true,
            duplicadoTurma: true,
            motivo: 'RA "$rawRa" já cadastrado na turma',
          ),
        );
        avisos.add('Linha $numeroLinha: RA "$rawRa" já cadastrado nesta turma.');
        totalDuplicadosTurma++;
        continue;
      }

      // Registro válido para importação
      final aluno = Aluno(
        id: '',
        nome: rawNome,
        ra: rawRa, // Preserva explicitamente como String
      );

      itens.add(
        ItemAnaliseImportacao(
          linha: numeroLinha,
          nome: rawNome,
          ra: rawRa,
          valido: true,
        ),
      );
      alunosValidos.add(aluno);
      totalValidos++;
    }

    return ResultadoAnaliseImportacao(
      itens: itens,
      alunosValidos: alunosValidos,
      totalValidos: totalValidos,
      totalInvalidos: totalInvalidos,
      totalDuplicadosArquivo: totalDuplicadosArquivo,
      totalDuplicadosTurma: totalDuplicadosTurma,
      avisos: avisos,
    );
  }

  static bool _ehColunaRa(String valor) {
    return valor == 'ra' ||
        valor == 'r.a.' ||
        valor == 'registro' ||
        valor == 'matrícula' ||
        valor == 'matricula' ||
        valor == 'ra do aluno' ||
        valor == 'ra aluno';
  }

  static bool _ehColunaNome(String valor) {
    return valor == 'nome' ||
        valor == 'aluno' ||
        valor == 'nome do aluno' ||
        valor == 'nome aluno' ||
        valor == 'estudante';
  }
}
