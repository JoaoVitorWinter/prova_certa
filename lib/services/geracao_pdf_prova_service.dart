import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/prova.dart';
import '../models/questao.dart';
import '../models/versao_prova.dart';

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
    if (prova.quantidadeQuestoes > 20) {
      throw ArgumentError.value(
        prova.quantidadeQuestoes,
        'quantidadeQuestoes',
        'Uma prova pode ter no máximo 20 questões.',
      );
    }
    final versao = _selecionarVersao(prova, numeroVersao);
    final questoes = versao?.questoes.isNotEmpty == true
        ? versao!.questoes
        : _questoesDaProva(prova);
    final qrData = jsonEncode({
      'app': 'prova_certa',
      'tipo': 'gabarito_prova',
      'versao': versao?.numero ?? numeroVersao,
      'provaId': prova.id,
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
              'Preencha o círculo até ficar visivelmente escuro, sem ultrapassar o contorno.',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 8),
            _tabelaRespostas(quantidadeQuestoes),
          ],
        ),
      ),
    );
  }

  pw.Widget _tabelaRespostas(int quantidadeQuestoes) {
    final quantidadePorGrupo = (quantidadeQuestoes / 2).ceil();
    final inicioSegundoGrupo = quantidadePorGrupo;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _tabelaGrupo(quantidadeQuestoes, 1, quantidadePorGrupo),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: _tabelaGrupo(
            quantidadeQuestoes,
            inicioSegundoGrupo + 1,
            quantidadeQuestoes,
          ),
        ),
      ],
    );
  }

  pw.Widget _tabelaGrupo(int quantidadeQuestoes, int inicio, int fim) {
    if (inicio > quantidadeQuestoes) {
      return pw.SizedBox();
    }

    final fimReal = fim > quantidadeQuestoes ? quantidadeQuestoes : fim;
    final headers = ['Questão', 'A', 'B', 'C', 'D', 'E'];
    return pw.Table(
      border: pw.TableBorder.all(width: .7),
      columnWidths: const {
        0: pw.FixedColumnWidth(42),
        1: pw.FlexColumnWidth(),
        2: pw.FlexColumnWidth(),
        3: pw.FlexColumnWidth(),
        4: pw.FlexColumnWidth(),
        5: pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          children: [
            for (final header in headers)
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Center(
                  child: pw.Text(
                    header,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        for (var questao = inicio; questao <= fimReal; questao++)
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(3),
                child: pw.Center(child: pw.Text('$questao')),
              ),
              for (var alternativa = 0; alternativa < 5; alternativa++)
                pw.Padding(
                  padding: const pw.EdgeInsets.all(3),
                  child: pw.Center(
                    child: pw.Container(
                      width: 15,
                      height: 15,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(width: 1),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
