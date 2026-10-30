import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prova_certa/mocks/questoes_mock.dart';
import 'package:prova_certa/models/alternativa.dart';
import 'package:prova_certa/models/questao.dart';
import 'package:prova_certa/screens/banco_questoes_screen.dart';
import 'package:prova_certa/services/questao_service.dart';

class FakeQuestaoService extends QuestaoService {
  final Map<String, Questao> _db = {};
  final StreamController<List<Questao>> _controller =
      StreamController<List<Questao>>.broadcast();
  int _contador = 0;
  bool falharAoSalvar;

  FakeQuestaoService({
    List<Questao> iniciais = const [],
    this.falharAoSalvar = false,
  }) {
    for (final questao in iniciais) {
      _db[questao.id] = questao;
    }
  }

  List<Questao> get todas => _db.values.toList();

  void _notificar() => _controller.add(todas);

  @override
  Stream<List<Questao>> monitorarQuestoes({String? userId}) {
    return Stream<List<Questao>>.multi((controller) {
      controller.add(todas);
      final sub = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Future<List<Questao>> listarQuestoes({String? userId}) async => todas;

  @override
  Future<Questao> criarQuestao(Questao questao, {String? userId}) async {
    if (falharAoSalvar) {
      throw Exception('Falha ao salvar no Firestore.');
    }
    final nova = questao.copyWith(id: 'fake_${++_contador}');
    _db[nova.id] = nova;
    _notificar();
    return nova;
  }

  @override
  Future<Questao> atualizarQuestao(Questao questao, {String? userId}) async {
    _db[questao.id] = questao;
    _notificar();
    return questao;
  }

  @override
  Future<void> excluirQuestao(String questaoId, {String? userId}) async {
    _db.remove(questaoId);
    _notificar();
  }
}

Questao questaoExemplo({String id = 'q_exemplo'}) {
  return Questao(
    id: id,
    enunciado: 'Qual é a unidade básica da vida?',
    alternativas: [
      Alternativa(letra: 'A', texto: 'Átomo'),
      Alternativa(letra: 'B', texto: 'Célula'),
    ],
    correta: 'B',
    assunto: 'Citologia',
    dificuldade: 'Fácil',
    disciplina: 'Biologia',
  );
}

Future<void> abrirBanco(WidgetTester tester, FakeQuestaoService service) async {
  await tester.pumpWidget(
    MaterialApp(home: BancoQuestoesScreen(questaoService: service)),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('QuestaoService - validação', () {
    final service = QuestaoService();

    test('rejeita questão sem enunciado', () {
      expect(
        () => service.criarQuestao(
          questaoExemplo().copyWith(enunciado: '  '),
          userId: 'prof',
        ),
        throwsArgumentError,
      );
    });

    test('rejeita questão com menos de 2 alternativas', () {
      expect(
        () => service.criarQuestao(
          questaoExemplo().copyWith(
            alternativas: [Alternativa(letra: 'A', texto: 'Única')],
            correta: 'A',
          ),
          userId: 'prof',
        ),
        throwsArgumentError,
      );
    });

    test('rejeita alternativa correta inexistente', () {
      expect(
        () => service.criarQuestao(
          questaoExemplo().copyWith(correta: 'E'),
          userId: 'prof',
        ),
        throwsArgumentError,
      );
    });

    test('rejeita atualização sem id', () {
      expect(
        () => service.atualizarQuestao(
          questaoExemplo(id: ''),
          userId: 'prof',
        ),
        throwsArgumentError,
      );
    });
  });

  group('BancoQuestoesScreen', () {
    testWidgets('mostra estado vazio quando não há questões', (tester) async {
      await abrirBanco(tester, FakeQuestaoService());

      expect(find.text('Nenhuma questão cadastrada'), findsOneWidget);
      expect(find.text('Modo demonstrativo'), findsNothing);
    });

    testWidgets('lista e filtra por dificuldade', (tester) async {
      await abrirBanco(tester, FakeQuestaoService(iniciais: questoesMock));

      expect(find.text('10 questões encontradas'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChipFiltro, 'Difícil'));
      await tester.pumpAndSettle();

      expect(find.text('1 questão encontrada'), findsOneWidget);
    });

    testWidgets('cadastra uma nova questão', (tester) async {
      final service = FakeQuestaoService();
      await abrirBanco(tester, service);

      await tester.tap(find.text('+ Adicionar'));
      await tester.pumpAndSettle();

      final campos = find.byType(TextField);
      await tester.enterText(campos.at(0), 'Qual organela faz fotossíntese?');
      await tester.enterText(campos.at(1), 'Botânica');
      for (var i = 0; i < 5; i++) {
        await tester.enterText(campos.at(2 + i), 'Alternativa $i');
      }
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Criar questão'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Criar questão'));
      await tester.pumpAndSettle();

      expect(service.todas, hasLength(1));
      expect(service.todas.first.assunto, 'Botânica');
      expect(service.todas.first.alternativas, hasLength(5));
      expect(find.text('1 questão encontrada'), findsOneWidget);
      expect(find.text('Questão criada com sucesso.'), findsOneWidget);
    });

    testWidgets('mantém o formulário aberto quando o salvamento falha',
        (tester) async {
      final service = FakeQuestaoService(falharAoSalvar: true);
      await abrirBanco(tester, service);

      await tester.tap(find.text('+ Adicionar'));
      await tester.pumpAndSettle();

      final campos = find.byType(TextField);
      await tester.enterText(campos.at(0), 'Enunciado');
      await tester.enterText(campos.at(1), 'Assunto');
      for (var i = 0; i < 5; i++) {
        await tester.enterText(campos.at(2 + i), 'Alternativa $i');
      }
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Criar questão'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Criar questão'));
      await tester.pumpAndSettle();

      expect(service.todas, isEmpty);
      expect(find.text('Nova questão'), findsOneWidget);
      expect(find.text('Falha ao salvar no Firestore.'), findsOneWidget);
    });

    testWidgets('edita uma questão existente', (tester) async {
      final service = FakeQuestaoService(iniciais: [questaoExemplo()]);
      await abrirBanco(tester, service);

      await tester.tap(find.text('Qual é a unidade básica da vida?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).at(0),
        'Qual é a menor unidade da vida?',
      );
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Salvar alterações'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Salvar alterações'));
      await tester.pumpAndSettle();

      expect(service.todas.single.id, 'q_exemplo');
      expect(service.todas.single.enunciado, 'Qual é a menor unidade da vida?');
      expect(find.text('Qual é a menor unidade da vida?'), findsOneWidget);
    });

    testWidgets('exclui uma questão após confirmação', (tester) async {
      final service = FakeQuestaoService(iniciais: [questaoExemplo()]);
      await abrirBanco(tester, service);

      await tester.tap(find.text('Qual é a unidade básica da vida?'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(BotaoAcao, 'Excluir'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Excluir').last);
      await tester.pumpAndSettle();

      expect(service.todas, isEmpty);
      expect(find.text('Nenhuma questão cadastrada'), findsOneWidget);
    });
  });
}
