import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
        'Nota',
        'Acertos',
        'Total de questões',
        for (var i = 1; i <= totalQuestoes; i++) 'Q$i',
      ],
      for (final r in resultado.porAluno)
        [
          r.aluno.nome,
          r.aluno.ra,
          _decimal(r.nota),
          r.acertos,
          totalQuestoes,
          for (var i = 0; i < totalQuestoes; i++)
            i < r.alternativasMarcadas.length ? r.alternativasMarcadas[i] : '',
        ],
      [],
      ['Média da turma', '', _decimal(resultado.media)],
      ['Menor nota', '', _decimal(resultado.minimo)],
      ['Maior nota', '', _decimal(resultado.maximo)],
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
        'Gabarito',
        '% de acerto',
        for (final l in letras) 'Marcaram $l',
      ],
      for (final q in resultado.porQuestao)
        [
          q.numero,
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

  /// Grava o CSV em um arquivo temporário e abre a tela de compartilhamento.
  static Future<File> exportar({
    required String conteudo,
    required String nomeArquivo,
    required String assunto,
  }) async {
    final pasta = await getTemporaryDirectory();
    final arquivo = File('${pasta.path}/$nomeArquivo');
    await arquivo.writeAsString(conteudo, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(arquivo.path, mimeType: 'text/csv')],
        subject: assunto,
        title: assunto,
      ),
    );

    return arquivo;
  }

  static String _decimal(double valor) {
    return valor.toStringAsFixed(1).replaceAll('.', ',');
  }
}
