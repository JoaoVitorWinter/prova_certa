import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/prova.dart';
import '../models/questao.dart';
import '../models/versao_prova.dart';
import 'folha_respostas_layout.dart';

class GeracaoPdfProvaService {
  Future<Uint8List> gerar({required Prova prova, int numeroVersao = 1}) async {
    final documentos = await _prepararDocumento(prova);
    _adicionarVersao(documentos, prova, numeroVersao);
    return documentos.save();
  }

  Future<Uint8List> gerarTodas({required Prova prova}) async {
    final documento = await _prepararDocumento(prova);
    for (var numero = 1; numero <= _quantidadeVersoes(prova); numero++) {
      _adicionarVersao(documento, prova, numero);
    }
    return documento.save();
  }

  Future<List<Uint8List>> gerarTodasSeparadas({required Prova prova}) async {
    final arquivos = <Uint8List>[];
    for (var numero = 1; numero <= _quantidadeVersoes(prova); numero++) {
      arquivos.add(await gerar(prova: prova, numeroVersao: numero));
    }
    return arquivos;
  }

  int _quantidadeVersoes(Prova prova) {
    return prova.numeroVersoes.clamp(1, 4);
  }

  Future<pw.Document> _prepararDocumento(Prova prova) async {
    final fonte = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    final fonteNegrito = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
    );
    final documento = pw.Document(
      theme: pw.ThemeData.withFont(base: fonte, bold: fonteNegrito),
    );
    return documento;
  }

  void _adicionarVersao(pw.Document documento, Prova prova, int numeroVersao) {
    final versao = _selecionarVersao(prova, numeroVersao);
    final questoes = versao?.questoes.isNotEmpty == true
        ? versao!.questoes
        : _questoesDaProva(prova);
    final gabarito = versao?.gabarito ?? _gabaritoDaProva(prova, questoes);
    final qrData = jsonEncode({
      'app': 'prova_certa',
      'tipo': 'gabarito_prova',
      'versao': versao?.numero ?? numeroVersao,
      'provaId': prova.id,
      'turmaId': prova.turma.id,
      'gabarito': gabarito,
    });

    _adicionarCaderno(
      documento,
      prova,
      questoes,
      versao?.numero ?? numeroVersao,
    );
    _adicionarFolhaRespostas(documento, prova, questoes.length, qrData);
  }

  VersaoProva? _selecionarVersao(Prova prova, int numero) {
    if (numero < 1 || numero > 4) {
      throw ArgumentError.value(
        numero,
        'numeroVersao',
        'Use uma versão de 1 a 4.',
      );
    }
    for (final versao in prova.versoes ?? const <VersaoProva>[]) {
      if (versao.numero == numero) return versao;
    }
    return null;
  }

  List<Questao> _questoesDaProva(Prova prova) {
    final snapshot = prova.extrairQuestoesSnapshot();
    if (snapshot.isNotEmpty) {
      return snapshot.map(Questao.fromMap).toList();
    }
    return prova.questoes.whereType<Questao>().toList();
  }

  List<String> _gabaritoDaProva(Prova prova, List<Questao> questoes) {
    if (prova.gabaritoOficial != null &&
        prova.gabaritoOficial!.length == questoes.length) {
      return prova.gabaritoOficial!;
    }
    return questoes.map((questao) => questao.correta).toList();
  }

  void _adicionarCaderno(
    pw.Document documento,
    Prova prova,
    List<Questao> questoes,
    int numeroVersao,
  ) {
    final paginas = <List<Questao>>[];
    for (var i = 0; i < questoes.length; i += 5) {
      final fim = (i + 5 < questoes.length) ? i + 5 : questoes.length;
      paginas.add(questoes.sublist(i, fim));
    }
    if (paginas.isEmpty) paginas.add(const []);

    for (var pagina = 0; pagina < paginas.length; pagina++) {
      documento.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(42.52),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _cabecalho(
                'Caderno de questões - versão $numeroVersao',
                'CADERNO ${numeroVersao.toString().padLeft(2, '0')}',
              ),
              pw.SizedBox(height: 12),
              if (pagina == 0) ...[
                _identificacao(prova),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Instruções',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Leia cada questão e assinale uma única alternativa na folha de respostas.\n'
                  'Use caneta azul ou preta. Não dobre ou rasure a folha de respostas.',
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
                pw.SizedBox(height: 12),
              ],
              for (var indice = 0; indice < paginas[pagina].length; indice++)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: _questao(
                    paginas[pagina][indice],
                    pagina * 5 + indice + 1,
                  ),
                ),
            ],
          ),
        ),
      );
    }
  }

  pw.Widget _questao(Questao questao, int numero) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '$numero. ${questao.enunciado}',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        for (final alternativa in questao.alternativas)
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12, bottom: 3),
            child: pw.Text(
              '${alternativa.letra}) ${alternativa.texto}',
              style: const pw.TextStyle(fontSize: 8.5),
            ),
          ),
      ],
    );
  }

  pw.Widget _identificacao(Prova prova) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: .7)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            prova.nome,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Turma: ${prova.turma.nome}    Data: ____/____/______'),
          pw.SizedBox(height: 5),
          pw.Text(
            'Nome: ____________________________________________________________',
          ),
        ],
      ),
    );
  }

  pw.Widget _cabecalho(String titulo, String pagina) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: PdfColors.black,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'AVALIAÇÃO',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                titulo,
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
              ),
            ],
          ),
          pw.Text(
            pagina,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _adicionarFolhaRespostas(
    pw.Document documento,
    Prova prova,
    int quantidadeQuestoes,
    String qrData,
  ) {
    documento.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(42.52),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _cabecalho('Folha de respostas', ''),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(width: .7)),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'IDENTIFICAÇÃO DO ALUNO',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'Nome: ______________________________________________',
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text('Turma: ____________________'),
                        pw.SizedBox(height: 8),
                        pw.Text('RA / matrícula: ____________________'),
                      ],
                    ),
                  ),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: qrData,
                    width: 92,
                    height: 92,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              'MARCAÇÕES',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Preencha o círculo até ficar visivelmente escuro, sem ultrapassar o contorno. '
              'Não rasure nem cubra os quadrados pretos dos cantos: eles orientam a leitura pela câmera.',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 8),
            _tabelaRespostas(quantidadeQuestoes),
          ],
        ),
      ),
    );
  }

  /// Grade de respostas desenhada com geometria fixa (ver
  /// [FolhaRespostasLayout]) e com quatro marcadores pretos nos cantos, que o
  /// leitor usa para localizar as bolhas na fotografia.
  pw.Widget _tabelaRespostas(int quantidadeQuestoes) {
    final layout = FolhaRespostasLayout(quantidadeQuestoes);
    const largura = FolhaRespostasLayout.largura;
    final colunaAlternativa = layout.larguraColunaAlternativa;

    pw.Widget celula(
      String texto,
      double larguraCelula,
      double alturaCelula, {
      bool negrito = false,
      double tamanho = 9,
    }) {
      return pw.SizedBox(
        width: larguraCelula,
        height: alturaCelula,
        child: pw.Center(
          child: pw.Text(
            texto,
            style: pw.TextStyle(
              fontSize: tamanho,
              fontWeight: negrito ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      );
    }

    return pw.SizedBox(
      width: largura,
      height: layout.altura,
      child: pw.Stack(
        children: [
          pw.Positioned(
            left: 0,
            top: 0,
            child: pw.CustomPaint(
              size: PdfPoint(largura, layout.altura),
              painter: (canvas, size) => _desenharGrade(canvas, layout),
            ),
          ),
          pw.Positioned(
            left: layout.tabelaEsquerda,
            top: layout.tabelaTopo,
            child: celula(
              'Questão',
              FolhaRespostasLayout.larguraColunaQuestao,
              FolhaRespostasLayout.alturaCabecalho,
              negrito: true,
              tamanho: 8.5,
            ),
          ),
          for (var i = 0; i < FolhaRespostasLayout.alternativas.length; i++)
            pw.Positioned(
              left: layout.centroXAlternativa(i) - colunaAlternativa / 2,
              top: layout.tabelaTopo,
              child: celula(
                FolhaRespostasLayout.alternativas[i],
                colunaAlternativa,
                FolhaRespostasLayout.alturaCabecalho,
                negrito: true,
                tamanho: 10,
              ),
            ),
          for (var q = 0; q < quantidadeQuestoes; q++)
            pw.Positioned(
              left: layout.tabelaEsquerda,
              top: layout.centroYQuestao(q) - FolhaRespostasLayout.alturaLinha / 2,
              child: celula(
                '${q + 1}',
                FolhaRespostasLayout.larguraColunaQuestao,
                FolhaRespostasLayout.alturaLinha,
              ),
            ),
        ],
      ),
    );
  }

  /// Desenha marcadores, linhas e bolhas. O PDF usa a origem no canto
  /// inferior esquerdo, por isso as coordenadas verticais são invertidas.
  void _desenharGrade(PdfGraphics canvas, FolhaRespostasLayout layout) {
    final altura = layout.altura;
    double y(double topo) => altura - topo;

    // Marcadores de referência (quadrados pretos cheios).
    canvas.setFillColor(PdfColors.black);
    const lado = FolhaRespostasLayout.tamanhoMarcador;
    for (final centro in layout.centrosMarcadores) {
      canvas.drawRect(
        centro.x - lado / 2,
        y(centro.y + lado / 2),
        lado,
        lado,
      );
    }
    canvas.fillPath();

    // Linhas da tabela.
    canvas
      ..setStrokeColor(PdfColors.black)
      ..setLineWidth(0.7);
    final esquerda = layout.tabelaEsquerda;
    final direita = esquerda + layout.larguraTabela;
    final topo = layout.tabelaTopo;
    final base = topo + layout.alturaTabela;
    canvas.drawRect(esquerda, y(base), layout.larguraTabela, layout.alturaTabela);
    for (var q = 0; q < layout.quantidadeQuestoes; q++) {
      final linha = topo +
          FolhaRespostasLayout.alturaCabecalho +
          FolhaRespostasLayout.alturaLinha * q;
      canvas.drawLine(esquerda, y(linha), direita, y(linha));
    }
    for (var i = 0; i < FolhaRespostasLayout.alternativas.length; i++) {
      final coluna = esquerda +
          FolhaRespostasLayout.larguraColunaQuestao +
          layout.larguraColunaAlternativa * i;
      canvas.drawLine(coluna, y(topo), coluna, y(base));
    }
    canvas.strokePath();

    // Bolhas.
    canvas.setLineWidth(1);
    const raio = FolhaRespostasLayout.diametroBolha / 2;
    for (var q = 0; q < layout.quantidadeQuestoes; q++) {
      for (var i = 0; i < FolhaRespostasLayout.alternativas.length; i++) {
        canvas.drawEllipse(
          layout.centroXAlternativa(i),
          y(layout.centroYQuestao(q)),
          raio,
          raio,
        );
      }
    }
    canvas.strokePath();
  }
}
