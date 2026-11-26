import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

import '../models/resultado.dart';

/// Gera planilhas CSV com os resultados de uma prova e abre o compartilhamento
/// do sistema (WhatsApp, e-mail, Drive...). Usa ';' e BOM UTF-8 para o Excel
/// em português abrir as colunas e os acentos corretamente.
class ExportacaoService {
  static final _csv = Csv.excel();

  /// Uma linha por aluno: dados, nota, acertos e a alternativa marcada em cada questão.
  static String gerarCsvNotas(ResultadoProva resultado) {
    final totalQuestoes = resultado.porQuestao.length;

    final linhas = <List<dynamic>>[
      [
        'Aluno',
        'RA',
        'Versão',
        'Gabarito da versão',
        'Nota',
        'Acertos',
        'Total de questões',
        for (var i = 1; i <= totalQuestoes; i++) 'Q$i',
      ],
      for (final r in resultado.porAluno)
        [
          r.aluno.nome,
          r.aluno.ra,
          r.numeroVersao ?? '',
          _gabaritoOriginal(r).join(''),
          _decimal(r.nota),
          r.acertos,
          totalQuestoes,
          for (var i = 0; i < totalQuestoes; i++)
            i < r.alternativasMarcadas.length ? _respostaOriginal(r, i) : '',
        ],
      [],
      ['Média da turma', '', '', '', _decimal(resultado.media)],
      ['Menor nota', '', '', '', _decimal(resultado.minimo)],
      ['Maior nota', '', '', '', _decimal(resultado.maximo)],
    ];

    return _csv.encode(linhas);
  }

  /// Uma linha por questão: gabarito, % de acerto e quantos marcaram cada alternativa.
  static String gerarCsvQuestoes(ResultadoProva resultado) {
    final letras = <String>{
      for (final q in resultado.porQuestao)
        for (final a in q.alternativas) a.letra,
    }.toList()..sort();

    final linhas = <List<dynamic>>[
      [
        'Questão',
        'Enunciado',
        'Gabarito',
        '% de acerto',
        for (final l in letras)
          'Alternativa $l'
              '${_textoAlternativa(resultado, l).isEmpty ? '' : ' - ${_textoAlternativa(resultado, l)}'}',
      ],
      for (final q in resultado.porQuestao)
        [
          q.numero,
          q.enunciado,
          q.alternativaCorreta,
          _decimal(q.percentualAcerto),
          for (final l in letras)
            q.alternativas
                .where((a) => a.letra == l)
                .fold<int>(0, (soma, a) => soma + a.quantidade),
        ],
    ];

    return _csv.encode(linhas);
  }

  /// Nome de arquivo seguro, ex.: "notas_1a_prova_bimestral_citologia.csv".
  static String nomeArquivo(String prefixo, ResultadoProva resultado) {
    const acentos = 'áàâãäªéèêëíìîïóòôõöºúùûüçñ';
    const semAcento = 'aaaaaaeeeeiiiioooooouuuucn';

    var nome = resultado.prova.nome.toLowerCase();
    for (var i = 0; i < acentos.length; i++) {
      nome = nome.replaceAll(acentos[i], semAcento[i]);
    }
    nome = nome
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    return '${prefixo}_$nome.csv';
  }

  static String _textoAlternativa(ResultadoProva resultado, String letra) {
    for (final questao in resultado.porQuestao) {
      for (final alternativa in questao.alternativas) {
        if (alternativa.letra == letra && alternativa.texto.isNotEmpty) {
          return alternativa.texto;
        }
      }
    }
    return '';
  }

  /// Salva o CSV diretamente no dispositivo ou inicia o download no navegador.
  static Future<String?> exportar({
    required String conteudo,
    required String nomeArquivo,
    required String assunto,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode('\uFEFF$conteudo'));
    final resultado = await FilePicker.saveFile(
      fileName: nomeArquivo,
      bytes: bytes,
      mimeType: 'text/csv',
      dialogTitle: assunto,
    );
    return resultado?.toString();
  }

  static List<String> _gabaritoOriginal(ResultadoAluno resultado) {
    final gabarito = resultado.gabaritoCorreto ?? const <String>[];
    final snapshot = resultado.questoesSnapshot ?? const [];
    final original = <String>[];
    for (var i = 0; i < gabarito.length; i++) {
      original.add(_letraOriginal(snapshot, i, gabarito[i]));
    }
    return original;
  }

  static String _respostaOriginal(ResultadoAluno resultado, int indice) {
    if (indice >= resultado.alternativasMarcadas.length) return '';
    return _letraOriginal(
      resultado.questoesSnapshot ?? const [],
      indice,
      resultado.alternativasMarcadas[indice],
    );
  }

  static String _letraOriginal(
    List<Map<String, dynamic>> snapshot,
    int indice,
    String letraVersao,
  ) {
    if (indice >= snapshot.length) return letraVersao;
    final rawAlternativas =
        snapshot[indice]['alternativas'] as List<dynamic>? ?? const [];
    final letra = letraVersao.trim().toUpperCase();
    for (final raw in rawAlternativas) {
      if (raw is Map) {
        final letraVersaoAtual = raw['letra']?.toString().trim().toUpperCase();
        if (letraVersaoAtual == letra) {
          return raw['letraOriginal']?.toString().trim().toUpperCase() ?? letra;
        }
      }
    }
    return letra;
  }

  static String _decimal(double valor) {
    return valor.toStringAsFixed(1).replaceAll('.', ',');
  }
}
