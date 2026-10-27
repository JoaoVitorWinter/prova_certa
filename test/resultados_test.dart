import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prova_certa/models/aluno.dart';
import 'package:prova_certa/models/prova.dart';
import 'package:prova_certa/models/resultado.dart';
import 'package:prova_certa/models/turma.dart';
import 'package:prova_certa/screens/correcao_concluida_screen.dart';
import 'package:prova_certa/screens/folhas_screen.dart';
import 'package:prova_certa/screens/home_screen.dart';
import 'package:prova_certa/screens/resultados_screen.dart';
import 'package:prova_certa/services/exportacao_service.dart';
import 'package:prova_certa/services/resultado_service.dart';
import 'package:prova_certa/services/turma_service.dart';

/// ResultadoService em memória: guarda as correções e as publica no stream.
class FakeResultadoService extends ResultadoService {
  final Map<String, ResultadoProva> _porProva = {};
  final _controller = StreamController<List<ResultadoProva>>.broadcast();
  final List<List<ResultadoAluno>> salvamentos = [];
  bool falharAoSalvar;

  FakeResultadoService({
    List<ResultadoProva> iniciais = const [],
    this.falharAoSalvar = false,
  }) {
    for (final r in iniciais) {
      _porProva[r.prova.id] = r;
    }
  }

  List<ResultadoProva> get _lista => _porProva.values.toList()
    ..sort((a, b) => b.prova.dataAplicacao.compareTo(a.prova.dataAplicacao));

  @override
  Stream<List<ResultadoProva>> monitorarResultados({String? userId}) {
    return Stream<List<ResultadoProva>>.multi((controller) {
      controller.add(_lista);
      final sub = _controller.stream.listen(controller.add);
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Future<ResultadoProva> salvarCorrecao({
    required Prova prova,
    required List<String> gabarito,
    required List<ResultadoAluno> resultados,
    String? userId,
  }) async {
    if (falharAoSalvar) throw StateError('sem conexão');
    salvamentos.add(resultados);
    final resultado = ResultadoProva.calcular(
      prova: prova,
      gabarito: gabarito,
      porAluno: resultados,
    );
    _porProva[prova.id] = resultado;
    _controller.add(_lista);
    return resultado;
  }
}

class _FakeTurmaAlunos extends TurmaService {
  final List<Aluno> alunos;

  _FakeTurmaAlunos(this.alunos);

  @override
  Future<List<Aluno>> listarAlunos({
    required String turmaId,
    String? userId,
  }) async => alunos;
}

final _ana = Aluno(id: 'a1', nome: 'Ana Souza', ra: '000123');
final _bruno = Aluno(id: 'a2', nome: 'Bruno Lima', ra: '000456');
final _carla = Aluno(id: 'a3', nome: 'Carla Dias', ra: '000789');

final _turma = Turma(
  id: 't1',
  nome: '1º A',
  ano: '1º Ano',
  disciplina: 'Biologia',
  periodo: 'Manhã',
  alunos: [_ana, _bruno, _carla],
);

final _prova = Prova(
  id: 'p1',
  nome: '1ª Prova — Citologia',
  turma: _turma,
  dataAplicacao: DateTime(2026, 10, 20),
  quantidadeQuestoes: 4,
  questoes: const [],
  status: ProvaStatus.encerrada,
);

const _gabarito = ['A', 'B', 'C', 'D'];

ResultadoProva _resultadoExemplo() {
  return ResultadoProva.calcular(
    prova: _prova,
    gabarito: _gabarito,
    porAluno: [
      ResultadoAluno.corrigir(
        aluno: _bruno,
        respostas: ['A', 'B', 'C', 'A'],
        gabarito: _gabarito,
      ),
      ResultadoAluno.corrigir(
        aluno: _ana,
        respostas: ['A', 'B', 'C', 'D'],
        gabarito: _gabarito,
      ),
      ResultadoAluno.corrigir(
        aluno: _carla,
        respostas: ['B', 'B', 'A', 'A'],
        gabarito: _gabarito,
      ),
    ],
  );
}

void main() {
  group('Cálculo dos resultados', () {
    test('ResultadoAluno.corrigir conta acertos e calcula nota de 0 a 10', () {
      final r = ResultadoAluno.corrigir(
        aluno: _ana,
        respostas: ['a', 'B', '?'],
        gabarito: _gabarito,
      );

      expect(r.acertos, 2);
      expect(r.nota, 5.0);
      // Questão sem resposta vira '?', mantendo o tamanho do gabarito.
      expect(r.alternativasMarcadas, ['A', 'B', '?', '?']);
    });

    test('ResultadoProva.calcular gera geral, por questão e por aluno', () {
      final resultado = _resultadoExemplo();

      expect(resultado.media, 6.7); // (10 + 7.5 + 2.5) / 3 = 6.67
      expect(resultado.minimo, 2.5);
      expect(resultado.maximo, 10.0);
      expect(resultado.distribuicao.map((f) => f.quantidade).toList(), [
        0,
        1,
        0,
        1,
        1,
      ]);

      // Alunos em ordem alfabética.
      expect(resultado.porAluno.map((r) => r.aluno.nome).toList(), [
        'Ana Souza',
        'Bruno Lima',
        'Carla Dias',
      ]);

      final q1 = resultado.porQuestao[0];
      expect(q1.alternativaCorreta, 'A');
      expect(q1.percentualAcerto, closeTo(66.7, .1));
      expect(q1.alternativas.firstWhere((a) => a.letra == 'B').quantidade, 1);

      expect(resultado.porQuestao[1].percentualAcerto, 100);
      expect(resultado.porQuestao[3].percentualAcerto, closeTo(33.3, .1));
    });

    test('resumo calculado sobrevive à ida e volta do Firestore', () {
      final resultado = _resultadoExemplo();
      final recriado = ResultadoProva.fromResumo(
        resultado.toFirestoreResumo(),
        prova: _prova,
        porAluno: resultado.porAluno,
      );

      expect(recriado.media, resultado.media);
      expect(recriado.porQuestao.length, 4);
      expect(recriado.distribuicao.length, 5);
    });
  });

  group('Exportação CSV', () {
    test('notas: uma linha por aluno, separador ; e vírgula decimal', () {
      final csv = ExportacaoService.gerarCsvNotas(_resultadoExemplo());
      final linhas = csv.replaceFirst('﻿', '').trim().split(RegExp(r'\r?\n'));

      expect(
        linhas.first,
        'Aluno;RA;Nota;Acertos;Total de questões;Q1;Q2;Q3;Q4',
      );
      expect(linhas[1], 'Ana Souza;000123;10,0;4;4;A;B;C;D');
      expect(linhas[2], 'Bruno Lima;000456;7,5;3;4;A;B;C;A');
      expect(csv, contains('Média da turma;;6,7'));
    });

    test('análise por questão: gabarito, % de acerto e contagem por letra', () {
      final csv = ExportacaoService.gerarCsvQuestoes(_resultadoExemplo());
      final linhas = csv.replaceFirst('﻿', '').trim().split(RegExp(r'\r?\n'));

      expect(
        linhas.first,
        'Questão;Gabarito;% de acerto;Marcaram A;Marcaram B;Marcaram C;Marcaram D',
      );
      expect(linhas[1], '1;A;66,7;2;1;0;0');
      expect(linhas.length, 5);
    });

    test('nome do arquivo sem acentos nem espaços', () {
      expect(
        ExportacaoService.nomeArquivo('notas', _resultadoExemplo()),
        'notas_1a_prova_citologia.csv',
      );
    });
  });

  group('Telas', () {
    testWidgets('Resultados: estado vazio quando nada foi corrigido', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResultadosScreen(resultadoService: FakeResultadoService()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma prova corrigida ainda'), findsOneWidget);
      expect(find.text('Corrigir prova'), findsOneWidget);
    });

    testWidgets('Resultados: mostra média, alunos e detalhe por questão', (
      tester,
    ) async {
      final service = FakeResultadoService(iniciais: [_resultadoExemplo()]);

      await tester.pumpWidget(
        MaterialApp(home: ResultadosScreen(resultadoService: service)),
      );
      await tester.pumpAndSettle();

      expect(find.text('1ª Prova — Citologia'), findsOneWidget);
      expect(find.text('6.7'), findsOneWidget);

      await tester.tap(find.text('Alunos'));
      await tester.pumpAndSettle();

      expect(find.text('3 alunos'), findsOneWidget);
      expect(find.text('RA: 000456 · 3/4 acertos'), findsOneWidget);

      await tester.tap(find.text('Bruno Lima'));
      await tester.pumpAndSettle();

      // Q4: marcou A, o correto era D.
      expect(find.text('certa: D'), findsOneWidget);
    });

    testWidgets('Folhas: lê uma folha por aluno da turma e salva a correção', (
      tester,
    ) async {
      final resultados = FakeResultadoService();

      await tester.pumpWidget(
        MaterialApp(
          home: FolhasScreen(
            prova: _prova,
            gabarito: _gabarito,
            turmaService: _FakeTurmaAlunos([_carla, _ana]),
            resultadoService: resultados,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0/2'), findsOneWidget);
      expect(find.text('Próxima folha: Ana Souza'), findsOneWidget);

      await tester.tap(find.text('Ler folha'));
      await tester.pumpAndSettle();
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('Finalizar com 1 folha'), findsOneWidget);

      await tester.tap(find.text('Ler folha'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Finalizar correção'));
      await tester.pumpAndSettle();

      expect(resultados.salvamentos.single.map((r) => r.aluno.nome), [
        'Ana Souza',
        'Carla Dias',
      ]);
      expect(resultados.salvamentos.single.first.provaId, 'p1');
      expect(find.byType(CorrecaoConcluidaScreen), findsOneWidget);
      expect(find.text('Média da turma'), findsOneWidget);
    });

    testWidgets('Folhas: avisa quando não consegue salvar no servidor', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FolhasScreen(
            prova: _prova,
            gabarito: _gabarito,
            turmaService: _FakeTurmaAlunos([_ana]),
            resultadoService: FakeResultadoService(falharAoSalvar: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ler folha'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finalizar correção'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Não foi possível salvar'), findsOneWidget);
    });

    testWidgets('Home: métricas e correções recentes vêm dos resultados', (
      tester,
    ) async {
      final service = FakeResultadoService(iniciais: [_resultadoExemplo()]);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            turmaService: _FakeTurmaAlunos(const []),
            resultadoService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Provas corrigidas'), findsOneWidget);
      expect(find.text('Folhas corrigidas'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('1ª Prova — Citologia'), findsOneWidget);
      expect(find.text('média 6.7'), findsOneWidget);
    });
  });
}
