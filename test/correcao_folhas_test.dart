import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prova_certa/models/alternativa.dart';
import 'package:prova_certa/models/aluno.dart';
import 'package:prova_certa/models/prova.dart';
import 'package:prova_certa/models/questao.dart';
import 'package:prova_certa/models/resultado.dart';
import 'package:prova_certa/models/turma.dart';
import 'package:prova_certa/models/versao_prova.dart';
import 'package:prova_certa/screens/folhas_screen.dart';
import 'package:prova_certa/screens/gabarito_qr_screen.dart';
import 'package:prova_certa/services/resultado_service.dart';
import 'package:prova_certa/services/turma_service.dart';

class _FakeResultados extends ResultadoService {
  final List<ResultadoAluno> salvos = [];

  @override
  Future<List<ResultadoAluno>> listarResultadosAlunos({
    required String provaId,
    String? userId,
  }) async => const [];

  @override
  Future<ResultadoProva> salvarCorrecao({
    required Prova prova,
    required List<String> gabarito,
    required List<ResultadoAluno> resultados,
    String? userId,
  }) async {
    salvos.addAll(resultados);
    return ResultadoProva.calcular(
      prova: prova,
      gabarito: gabarito,
      porAluno: resultados,
    );
  }
}

class _FakeTurma extends TurmaService {
  final List<Aluno> alunos;
  _FakeTurma(this.alunos);

  @override
  Future<List<Aluno>> listarAlunos({
    required String turmaId,
    String? userId,
  }) async => alunos;
}

final _ana = Aluno(id: 'a1', nome: 'Ana Souza', ra: '000123');

Questao _questao(String id, String enunciado) => Questao(
  id: id,
  enunciado: enunciado,
  alternativas: [
    Alternativa(letra: 'A', texto: '$enunciado - A', letraOriginal: 'B'),
    Alternativa(letra: 'B', texto: '$enunciado - B', letraOriginal: 'A'),
  ],
  correta: 'A',
  assunto: 'Citologia',
  dificuldade: 'Fácil',
  disciplina: 'Biologia',
);

final _prova = Prova(
  id: 'p1',
  nome: 'Prova de Citologia',
  turma: Turma(
    id: 't1',
    nome: '1º A',
    ano: '1º Ano',
    disciplina: 'Biologia',
    periodo: 'Manhã',
    alunos: [_ana],
  ),
  dataAplicacao: DateTime(2026, 10, 20),
  quantidadeQuestoes: 2,
  questoes: [_questao('q1', 'Um'), _questao('q2', 'Dois')],
  status: ProvaStatus.ativa,
  numeroVersoes: 2,
  gabaritoOficial: const ['A', 'B'],
  versoes: [
    VersaoProva(
      numero: 1,
      questoes: [_questao('q1', 'Um'), _questao('q2', 'Dois')],
      gabarito: const ['A', 'B'],
    ),
    VersaoProva(
      numero: 2,
      questoes: [_questao('q2', 'Dois'), _questao('q1', 'Um')],
      gabarito: const ['B', 'A'],
    ),
  ],
);

void main() {
  testWidgets('pular o QR deixa escolher a versão da folha', (tester) async {
    ResultadoLeituraGabarito? leitura;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              leitura = await Navigator.push<ResultadoLeituraGabarito>(
                context,
                MaterialPageRoute(
                  builder: (_) => GabaritoQrScreen(
                    prova: _prova,
                    retornarResultado: true,
                    nomeAluno: 'Ana Souza',
                  ),
                ),
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Folha de Ana Souza'), findsOneWidget);
    await tester.tap(
      find.text('Não conseguiu ler? Escolher a versão manualmente'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Versão 2'));
    await tester.pumpAndSettle();

    expect(leitura, isNotNull);
    expect(leitura!.numeroVersao, 2);
    expect(leitura!.versaoEscolhidaManualmente, isTrue);
    expect(leitura!.gabarito, ['B', 'A']);
    expect(leitura!.questoes.first['id'], 'q2');
  });

  testWidgets(
    'cada folha passa pelo QR e depois pela câmara, com opção de digitar',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final resultados = _FakeResultados();
      await tester.pumpWidget(
        MaterialApp(
          home: FolhasScreen(
            prova: _prova,
            turmaService: _FakeTurma([_ana]),
            resultadoService: resultados,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Escolher aluno e corrigir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ana Souza'));
      await tester.pumpAndSettle();

      expect(find.text('Folha de Ana Souza'), findsOneWidget);
      await tester.tap(
        find.text('Não conseguiu ler? Escolher a versão manualmente'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Versão 2'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.text('Fotografar folha'), findsOneWidget);
      await tester.tap(find.text('Digitar respostas manualmente'));
      await tester.pumpAndSettle();

      expect(find.text('Versão e respostas do aluno'), findsOneWidget);
      await tester.tap(find.text('Em branco').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('B').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar respostas'));
      await tester.pumpAndSettle();

      final salvo = resultados.salvos.single;
      expect(salvo.aluno.id, 'a1');
      expect(salvo.numeroVersao, 2);
      expect(salvo.alternativasMarcadas.first, 'B');
      expect(salvo.acertos, 1);
    },
  );
}
