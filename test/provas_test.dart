import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prova_certa/models/alternativa.dart';
import 'package:prova_certa/models/prova.dart';
import 'package:prova_certa/models/questao.dart';
import 'package:prova_certa/models/turma.dart';
import 'package:prova_certa/screens/nova_prova_screen.dart';
import 'package:prova_certa/screens/provas_screen.dart';
import 'package:prova_certa/services/prova_service.dart';
import 'package:prova_certa/services/questao_service.dart';
import 'package:prova_certa/services/turma_service.dart';

class FakeProvaService extends ProvaService {
  final Map<String, Prova> _db = {};
  final StreamController<List<Prova>> _controller =
      StreamController<List<Prova>>.broadcast();
  int _contador = 0;

  FakeProvaService({List<Prova> iniciais = const []}) {
    for (final prova in iniciais) {
      _db[prova.id] = prova;
    }
  }

  List<Prova> get todas => _db.values.toList();

  void _notificar() => _controller.add(todas);

  @override
  Stream<List<Prova>> monitorarProvas({String? userId}) {
    return Stream<List<Prova>>.multi((controller) {
      controller.add(todas);
      final sub = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Future<Prova> criarProva(Prova prova, {String? userId}) async {
    final nova = prova.copyWith(id: 'prova_${++_contador}');
    _db[nova.id] = nova;
    _notificar();
    return nova;
  }

  @override
  Future<void> atualizarStatus(
    String provaId,
    ProvaStatus status, {
    String? userId,
  }) async {
    _db[provaId] = _db[provaId]!.copyWith(status: status);
    _notificar();
  }

  @override
  Future<void> excluirProva(String provaId, {String? userId}) async {
    _db.remove(provaId);
    _notificar();
  }
}

class FakeTurmasProvaService extends TurmaService {
  final List<Turma> turmas;

  FakeTurmasProvaService(this.turmas);

  @override
  Stream<List<Turma>> monitorarTurmas({String? userId}) =>
      Stream.value(turmas);
}

class FakeQuestoesProvaService extends QuestaoService {
  List<Questao> questoes;
  final StreamController<List<Questao>> _controller =
      StreamController<List<Questao>>.broadcast();

  FakeQuestoesProvaService(this.questoes);

  void atualizar(List<Questao> novas) {
    questoes = novas;
    _controller.add(novas);
  }

  @override
  Stream<List<Questao>> monitorarQuestoes({String? userId}) {
    return Stream<List<Questao>>.multi((controller) {
      controller.add(questoes);
      final sub = _controller.stream.listen(controller.add);
      controller.onCancel = () => sub.cancel();
    });
  }
}

final turmaA = Turma(
  id: 'turma_a',
  nome: '1º A',
  ano: '1º Ano',
  disciplina: 'Biologia',
  periodo: 'Manhã',
  alunos: const [],
  quantidadeAlunos: 30,
);

Questao questao(String id, String enunciado, String correta) {
  return Questao(
    id: id,
    enunciado: enunciado,
    alternativas: [
      Alternativa(letra: 'A', texto: 'Alternativa A'),
      Alternativa(letra: 'B', texto: 'Alternativa B'),
      Alternativa(letra: 'C', texto: 'Alternativa C'),
    ],
    correta: correta,
    assunto: 'Citologia',
    dificuldade: 'Fácil',
    disciplina: 'Biologia',
  );
}

final questoesTeste = [
  questao('q1', 'Enunciado da questão um', 'A'),
  questao('q2', 'Enunciado da questão dois', 'C'),
  questao('q3', 'Enunciado da questão três', 'B'),
];

Prova prova(String id, String nome, ProvaStatus status, {int corrigidas = 0}) {
  return Prova(
    id: id,
    nome: nome,
    turma: turmaA,
    dataAplicacao: DateTime(2026, 10, 1),
    quantidadeQuestoes: 2,
    questoes: questoesTeste.take(2).toList(),
    status: status,
    resumoResultado:
        corrigidas > 0 ? {'totalFolhasCorrigidas': corrigidas} : null,
  );
}

Future<void> abrirProvas(WidgetTester tester, FakeProvaService service) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ProvasScreen(
        provaService: service,
        turmaService: FakeTurmasProvaService([turmaA]),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> abrirEtapaQuestoes(
  WidgetTester tester,
  FakeProvaService service,
  FakeQuestoesProvaService questaoService,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: NovaProvaScreen(
        provaService: service,
        turmaService: FakeTurmasProvaService([turmaA]),
        questaoService: questaoService,
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField).first, 'Prova de Citologia');
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('1º A — 1º Ano (30 alunos)').last);
  await tester.pumpAndSettle();

  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
}

Future<FakeProvaService> preencherNovaProva(WidgetTester tester) async {
  final service = FakeProvaService();

  await abrirEtapaQuestoes(
    tester,
    service,
    FakeQuestoesProvaService(questoesTeste),
  );

  await tester.tap(find.text('Enunciado da questão dois'));
  await tester.tap(find.text('Enunciado da questão um'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();

  return service;
}

Future<void> concluirTransicao(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

void main() {
  group('Prova - persistência', () {
    test('snapshot das questões não contém valores do servidor em arrays', () {
      final map = prova('p1', 'Prova', ProvaStatus.ativa).toFirestore();
      final snapshot = map['questoesSnapshot'] as List<Map<String, dynamic>>;

      expect(snapshot, hasLength(2));
      expect(snapshot.first['id'], 'q1');
      for (final item in snapshot) {
        expect(item.values.whereType<FieldValue>(), isEmpty);
      }
    });

    test('rejeita prova sem nome', () {
      expect(
        () => ProvaService().criarProva(
          prova('', '  ', ProvaStatus.ativa),
          userId: 'prof',
        ),
        throwsArgumentError,
      );
    });

    test('rejeita prova sem turma', () {
      expect(
        () => ProvaService().criarProva(
          prova('', 'Prova', ProvaStatus.ativa)
              .copyWith(turma: turmaA.copyWith(id: '')),
          userId: 'prof',
        ),
        throwsArgumentError,
      );
    });

    test('rejeita prova sem questões', () {
      expect(
        () => ProvaService().criarProva(
          prova('', 'Prova', ProvaStatus.ativa)
              .copyWith(questoes: const [], quantidadeQuestoes: 0),
          userId: 'prof',
        ),
        throwsArgumentError,
      );
    });
  });

  group('ProvasScreen', () {
    testWidgets('mostra estado vazio quando não há provas', (tester) async {
      await abrirProvas(tester, FakeProvaService());

      expect(find.text('Nenhuma prova criada'), findsOneWidget);
      expect(find.text('Demonstrativo'), findsNothing);
    });

    testWidgets('lista provas reais e filtra por status', (tester) async {
      await abrirProvas(
        tester,
        FakeProvaService(
          iniciais: [
            prova('p1', 'Prova Ativa', ProvaStatus.ativa, corrigidas: 3),
            prova('p2', 'Prova Rascunho', ProvaStatus.rascunho),
            prova('p3', 'Prova Encerrada', ProvaStatus.encerrada),
          ],
        ),
      );

      expect(find.text('Prova Ativa'), findsOneWidget);
      expect(find.text('Prova Rascunho'), findsOneWidget);
      expect(find.text('Prova Encerrada'), findsOneWidget);
      expect(find.text('3/30'), findsOneWidget);

      await tester.tap(find.text('Rascunhos'));
      await tester.pumpAndSettle();

      expect(find.text('Prova Rascunho'), findsOneWidget);
      expect(find.text('Prova Ativa'), findsNothing);
      expect(find.text('Prova Encerrada'), findsNothing);
    });

    testWidgets('publica um rascunho', (tester) async {
      final service = FakeProvaService(
        iniciais: [prova('p2', 'Prova Rascunho', ProvaStatus.rascunho)],
      );
      await abrirProvas(tester, service);

      await tester.tap(find.text('Prova Rascunho'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publicar prova'));
      await tester.pumpAndSettle();

      expect(service.todas.single.status, ProvaStatus.ativa);
      expect(find.text('Ativa'), findsOneWidget);
    });

    testWidgets('encerra uma prova ativa', (tester) async {
      final service = FakeProvaService(
        iniciais: [prova('p1', 'Prova Ativa', ProvaStatus.ativa)],
      );
      await abrirProvas(tester, service);

      await tester.tap(find.text('Prova Ativa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Encerrar prova'));
      await tester.pumpAndSettle();

      expect(service.todas.single.status, ProvaStatus.encerrada);
    });

    testWidgets('exclui uma prova após confirmação', (tester) async {
      final service = FakeProvaService(
        iniciais: [prova('p1', 'Prova Ativa', ProvaStatus.ativa)],
      );
      await abrirProvas(tester, service);

      await tester.tap(find.text('Prova Ativa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir prova'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Excluir'));
      await tester.pumpAndSettle();

      expect(service.todas, isEmpty);
      expect(find.text('Nenhuma prova criada'), findsOneWidget);
    });
  });

  group('NovaProvaScreen', () {
    testWidgets('não avança sem nome e turma', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NovaProvaScreen(
            provaService: FakeProvaService(),
            turmaService: FakeTurmasProvaService([turmaA]),
            questaoService: FakeQuestoesProvaService(questoesTeste),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final botao = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continuar'),
      );
      expect(botao.onPressed, isNull);
    });

    testWidgets('avisa quando não há turmas cadastradas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NovaProvaScreen(
            provaService: FakeProvaService(),
            turmaService: FakeTurmasProvaService(const []),
            questaoService: FakeQuestoesProvaService(questoesTeste),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Nenhuma turma cadastrada. Cadastre uma turma antes de criar a prova.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('salva a prova com turma, questões e gabarito', (tester) async {
      final service = await preencherNovaProva(tester);

      expect(find.text('Prova de Citologia'), findsOneWidget);

      await tester.tap(find.text('Gerar prova'));
      await tester.pump();

      final salva = service.todas.single;
      expect(salva.nome, 'Prova de Citologia');
      expect(salva.turma.id, 'turma_a');
      expect(salva.status, ProvaStatus.ativa);
      expect(salva.quantidadeQuestoes, 2);
      expect(salva.extrairQuestoesIds(), ['q2', 'q1']);
      expect(salva.gabaritoOficial, ['C', 'A']);

      final snapshot = salva.extrairQuestoesSnapshot();
      expect(snapshot.map((q) => q['enunciado']), [
        'Enunciado da questão dois',
        'Enunciado da questão um',
      ]);

      await concluirTransicao(tester);
    });

    testWidgets('mostra aviso quando o banco de questões está vazio',
        (tester) async {
      await abrirEtapaQuestoes(
        tester,
        FakeProvaService(),
        FakeQuestoesProvaService(const []),
      );

      expect(find.text('Nenhuma questão no banco'), findsOneWidget);
      expect(find.text('Abrir banco de questões'), findsOneWidget);
    });

    testWidgets('lista as questões do banco e respeita o limite',
        (tester) async {
      await abrirEtapaQuestoes(
        tester,
        FakeProvaService(),
        FakeQuestoesProvaService(questoesTeste),
      );

      expect(find.text('Enunciado da questão um'), findsOneWidget);
      expect(find.text('Enunciado da questão dois'), findsOneWidget);
      expect(find.text('Enunciado da questão três'), findsOneWidget);
      expect(find.text('Gabarito: C'), findsOneWidget);

      await tester.tap(find.text('Enunciado da questão um'));
      await tester.pumpAndSettle();
      expect(find.text('1 de 10 questões selecionadas'), findsOneWidget);
    });

    testWidgets('remove da seleção a questão excluída do banco',
        (tester) async {
      final questaoService = FakeQuestoesProvaService(questoesTeste);
      await abrirEtapaQuestoes(tester, FakeProvaService(), questaoService);

      await tester.tap(find.text('Enunciado da questão um'));
      await tester.tap(find.text('Enunciado da questão dois'));
      await tester.pumpAndSettle();
      expect(find.text('2 de 10 questões selecionadas'), findsOneWidget);

      questaoService.atualizar(
        questoesTeste.where((q) => q.id != 'q2').toList(),
      );
      await tester.pumpAndSettle();

      expect(find.text('Enunciado da questão dois'), findsNothing);
      expect(find.text('1 de 10 questões selecionadas'), findsOneWidget);
    });

    testWidgets('salva a prova como rascunho', (tester) async {
      final service = await preencherNovaProva(tester);

      await tester.tap(find.text('Salvar como rascunho'));
      await tester.pump();

      expect(service.todas.single.status, ProvaStatus.rascunho);

      await concluirTransicao(tester);
    });
  });
}
