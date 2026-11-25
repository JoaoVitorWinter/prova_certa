import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prova_certa/models/alternativa.dart';
import 'package:prova_certa/models/prova.dart';
import 'package:prova_certa/models/questao.dart';
import 'package:prova_certa/models/turma.dart';
import 'package:prova_certa/models/usuario.dart';
import 'package:prova_certa/screens/profile_screen.dart';
import 'package:prova_certa/services/auth_service.dart';
import 'package:prova_certa/services/prova_service.dart';
import 'package:prova_certa/services/questao_service.dart';
import 'package:prova_certa/services/turma_service.dart';

class _FakeAuthService extends AuthService {
  @override
  String? get currentUserId => 'prof_test_1';

  @override
  Stream<Usuario?> monitorarPerfil(String uid) {
    return Stream.value(
      Usuario(
        id: uid,
        nome: 'Professor Teste',
        email: 'professor@teste.com',
        instituicao: 'Escola Modelo',
      ),
    );
  }
}

class _MockTurmaService extends TurmaService {
  final List<Turma> _turmas = [];
  final StreamController<List<Turma>> _controller =
      StreamController<List<Turma>>.broadcast();

  bool emitError = false;

  void adicionar(Turma t) {
    _turmas.add(t);
    _controller.add(List.unmodifiable(_turmas));
  }

  void limpar() {
    _turmas.clear();
    _controller.add(const []);
  }

  @override
  Stream<List<Turma>> monitorarTurmas({String? userId}) {
    if (emitError) {
      return Stream.error(Exception('Erro de conexão com turmas'));
    }
    return Stream<List<Turma>>.multi((sc) {
      sc.add(List.unmodifiable(_turmas));
      final sub = _controller.stream.listen(sc.add, onError: sc.addError);
      sc.onCancel = () => sub.cancel();
    });
  }
}

class _MockProvaService extends ProvaService {
  final List<Prova> _provas = [];
  final StreamController<List<Prova>> _controller =
      StreamController<List<Prova>>.broadcast();

  bool emitError = false;

  void adicionar(Prova p) {
    _provas.add(p);
    _controller.add(List.unmodifiable(_provas));
  }

  void remover(String id) {
    _provas.removeWhere((p) => p.id == id);
    _controller.add(List.unmodifiable(_provas));
  }

  void limpar() {
    _provas.clear();
    _controller.add(const []);
  }

  @override
  Stream<List<Prova>> monitorarProvas({String? userId}) {
    if (emitError) {
      return Stream.error(Exception('Erro ao monitorar provas'));
    }
    return Stream<List<Prova>>.multi((sc) {
      sc.add(List.unmodifiable(_provas));
      final sub = _controller.stream.listen(sc.add, onError: sc.addError);
      sc.onCancel = () => sub.cancel();
    });
  }
}

class _MockQuestaoService extends QuestaoService {
  final List<Questao> _questoes = [];
  final StreamController<List<Questao>> _controller =
      StreamController<List<Questao>>.broadcast();

  bool emitError = false;

  void adicionar(Questao q) {
    _questoes.add(q);
    _controller.add(List.unmodifiable(_questoes));
  }

  void remover(String id) {
    _questoes.removeWhere((q) => q.id == id);
    _controller.add(List.unmodifiable(_questoes));
  }

  void limpar() {
    _questoes.clear();
    _controller.add(const []);
  }

  @override
  Stream<List<Questao>> monitorarQuestoes({String? userId}) {
    if (emitError) {
      return Stream.error(Exception('Erro ao monitorar questões'));
    }
    return Stream<List<Questao>>.multi((sc) {
      sc.add(List.unmodifiable(_questoes));
      final sub = _controller.stream.listen(sc.add, onError: sc.addError);
      sc.onCancel = () => sub.cancel();
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final turmaExemplo = Turma(
    id: 't1',
    nome: '1º Ano A',
    ano: '1º',
    disciplina: 'Matemática',
    periodo: 'Manhã',
    alunos: const [],
  );

  group('1. Contadores Reais da Tela de Perfil', () {
    late _MockTurmaService turmaService;
    late _MockProvaService provaService;
    late _MockQuestaoService questaoService;
    late _FakeAuthService authService;

    setUp(() {
      turmaService = _MockTurmaService();
      provaService = _MockProvaService();
      questaoService = _MockQuestaoService();
      authService = _FakeAuthService();
    });

    testWidgets('Exibe 0 nos três contadores quando coleções estão vazias',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            turmaService: turmaService,
            provaService: provaService,
            questaoService: questaoService,
            authService: authService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Nenhum valor mockado '4' ou '10' deve existir
      expect(find.text('4'), findsNothing);
      expect(find.text('10'), findsNothing);

      // Todos os 3 contadores (Turmas, Provas, Questões) devem apresentar 0
      expect(find.text('0'), findsNWidgets(3));
      // Labels presentes (Turmas e Provas aparecem no card e na barra inferior)
      expect(find.text('Turmas'), findsNWidgets(2));
      expect(find.text('Provas'), findsNWidgets(2));
      expect(find.text('Questões'), findsOneWidget);
    });

    testWidgets(
        'Atualização reativa dos contadores de Provas e Questões ao adicionar e remover itens',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            turmaService: turmaService,
            provaService: provaService,
            questaoService: questaoService,
            authService: authService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0'), findsNWidgets(3));

      // Adiciona 2 provas
      provaService.adicionar(
        Prova(
          id: 'p1',
          nome: 'Prova de Matemática',
          turma: turmaExemplo,
          quantidadeQuestoes: 1,
          questoes: const ['q1'],
          status: ProvaStatus.ativa,
          dataAplicacao: DateTime.now(),
        ),
      );
      provaService.adicionar(
        Prova(
          id: 'p2',
          nome: 'Prova de História',
          turma: turmaExemplo,
          quantidadeQuestoes: 1,
          questoes: const ['q2'],
          status: ProvaStatus.ativa,
          dataAplicacao: DateTime.now(),
        ),
      );

      // Adiciona 3 questões
      for (var i = 1; i <= 3; i++) {
        questaoService.adicionar(
          Questao(
            id: 'q$i',
            enunciado: 'Enunciado da questão $i',
            assunto: 'Assunto $i',
            dificuldade: 'Média',
            disciplina: 'Geral',
            alternativas: [
              Alternativa(letra: 'A', texto: 'Opção A'),
              Alternativa(letra: 'B', texto: 'Opção B'),
            ],
            correta: 'A',
          ),
        );
      }

      await tester.pumpAndSettle();

      // Turmas continua 0, Provas passa a 2, Questões passa a 3
      expect(find.text('0'), findsOneWidget); // Turmas
      expect(find.text('2'), findsOneWidget); // Provas
      expect(find.text('3'), findsOneWidget); // Questões

      // Remove uma prova -> contador deve atualizar para 1
      provaService.remover('p1');
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget); // Provas atualizadas
      expect(find.text('3'), findsOneWidget); // Questões continuam 3
    });

    testWidgets('Trata erros de stream exibindo "-" nos contadores afetados',
        (tester) async {
      provaService.emitError = true;

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            turmaService: turmaService,
            provaService: provaService,
            questaoService: questaoService,
            authService: authService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Provas com erro exibe '-', Turmas e Questões exibem '0'
      expect(find.text('-'), findsOneWidget);
      expect(find.text('0'), findsNWidgets(2));
    });
  });

  group('2. Opções Removidas no Perfil', () {
    testWidgets(
        'Opções Notificações e Aparência foram removidas e demais itens foram preservados',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            turmaService: _MockTurmaService(),
            provaService: _MockProvaService(),
            questaoService: _MockQuestaoService(),
            authService: _FakeAuthService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Opções removidas
      expect(find.text('Notificações'), findsNothing);
      expect(find.text('Alertas e avisos do sistema'), findsNothing);
      expect(find.text('Aparência'), findsNothing);
      expect(find.text('Tema claro / escuro'), findsNothing);

      // Opções preservadas
      expect(find.text('Editar perfil'), findsOneWidget);
      expect(find.text('Nome e informações pessoais'), findsOneWidget);
      expect(find.text('Sobre o app'), findsOneWidget);
      expect(find.text('Sair da conta'), findsOneWidget);
    });
  });
}
