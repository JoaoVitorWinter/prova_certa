import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prova_certa/models/aluno.dart';
import 'package:prova_certa/models/usuario.dart';
import 'package:prova_certa/screens/banco_questoes_screen.dart';
import 'package:prova_certa/screens/corrigir_prova_screen.dart';
import 'package:prova_certa/screens/edit_profile_screen.dart';
import 'package:prova_certa/screens/home_screen.dart';
import 'package:prova_certa/screens/profile_screen.dart';
import 'package:prova_certa/screens/provas_screen.dart';
import 'package:prova_certa/screens/resultados_screen.dart';
import 'package:prova_certa/services/auth_service.dart';

import 'resultados_test.dart';
import 'turmas_alunos_test.dart';

String valorMetrica(WidgetTester tester, String rotulo) {
  final metrica = find
      .ancestor(of: find.text(rotulo), matching: find.byType(Column))
      .first;
  return tester
      .widgetList<Text>(find.descendant(of: metrica, matching: find.byType(Text)))
      .first
      .data!;
}

class FakeAuditoriaAuthService extends AuthService {
  Usuario? _usuarioAtual;
  final StreamController<Usuario?> _perfilStreamController =
      StreamController<Usuario?>.broadcast();

  FakeAuditoriaAuthService({Usuario? usuarioInicial})
      : _usuarioAtual = usuarioInicial {
    if (_usuarioAtual != null) {
      _perfilStreamController.add(_usuarioAtual);
    }
  }

  @override
  String? get currentUserId => _usuarioAtual?.id;

  void definirUsuario(Usuario? usuario) {
    _usuarioAtual = usuario;
    _perfilStreamController.add(_usuarioAtual);
  }

  @override
  Stream<Usuario?> monitorarPerfil(String uid) {
    return Stream<Usuario?>.multi((controller) {
      controller.add(_usuarioAtual);
      final sub = _perfilStreamController.stream.listen((u) {
        controller.add(u);
      });
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Future<Usuario?> buscarPerfil(String uid) async {
    return _usuarioAtual;
  }

  @override
  Future<void> atualizarPerfil({
    required String uid,
    required String nome,
    required String instituicao,
  }) async {
    if (_usuarioAtual != null) {
      _usuarioAtual = _usuarioAtual!.copyWith(
        nome: nome,
        instituicao: instituicao,
      );
      _perfilStreamController.add(_usuarioAtual);
    }
  }

  @override
  Future<void> signOut() async {
    _usuarioAtual = null;
    _perfilStreamController.add(null);
  }
}

void main() {
  group('Etapa 5 — Auditoria e Consistência dos Dados', () {
    testWidgets('1. HomeScreen: exibe dados reais do professor autenticado',
        (tester) async {
      final fakeAuth = FakeAuditoriaAuthService(
        usuarioInicial: Usuario(
          id: 'user_123',
          nome: 'Carlos Drummond',
          email: 'carlos.drummond@escola.edu.br',
          instituicao: 'Colégio Estadual Central',
        ),
      );

      final fakeTurma = FakeTurmaService(initialUserId: 'user_123');

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            authService: fakeAuth,
            turmaService: fakeTurma,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prof. Ana Paula'), findsNothing);
      expect(find.text('E.E. Prof. Antônio Lemos'), findsNothing);
      expect(find.text('AP'), findsNothing);

      expect(find.text('Carlos Drummond'), findsOneWidget);
      expect(find.text('Colégio Estadual Central'), findsOneWidget);
      expect(find.text('CD'), findsOneWidget);
    });

    testWidgets(
        '2. HomeScreen: total de alunos é real e reativo às turmas (substitui 145 fixo)',
        (tester) async {
      final fakeAuth = FakeAuditoriaAuthService(
        usuarioInicial: Usuario(
          id: 'user_123',
          nome: 'Carlos Drummond',
          email: 'carlos@escola.edu.br',
          instituicao: 'Escola Central',
        ),
      );

      final fakeTurma = FakeTurmaService(initialUserId: 'user_123');

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            authService: fakeAuth,
            turmaService: fakeTurma,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('145'), findsNothing);
      expect(valorMetrica(tester, 'Alunos'), '0');

      final t1 = await fakeTurma.criarTurma(
        nome: '1º Ano A',
        ano: '1º Ano',
        disciplina: 'Física',
        periodo: 'Manhã',
      );
      await fakeTurma.cadastrarAluno(
        turmaId: t1.id,
        nome: 'Aluno Um',
        ra: '1001',
      );
      await fakeTurma.cadastrarAluno(
        turmaId: t1.id,
        nome: 'Aluno Dois',
        ra: '1002',
      );
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);

      final t2 = await fakeTurma.criarTurma(
        nome: '2º Ano B',
        ano: '2º Ano',
        disciplina: 'Física',
        periodo: 'Tarde',
      );
      await fakeTurma.importarAlunosLote(
        turmaId: t2.id,
        alunos: [
          Aluno(id: 'a1', nome: 'Aluno Tres', ra: '2001'),
          Aluno(id: 'a2', nome: 'Aluno Quatro', ra: '2002'),
          Aluno(id: 'a3', nome: 'Aluno Cinco', ra: '2003'),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
      expect(find.text('145'), findsNothing);
    });

    testWidgets('3. HomeScreen: métricas de correção vêm dos resultados reais',
        (tester) async {
      final fakeAuth = FakeAuditoriaAuthService();
      final fakeTurma = FakeTurmaService();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            authService: fakeAuth,
            turmaService: fakeTurma,
            resultadoService: FakeResultadoService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Provas (demo)'), findsNothing);
      expect(find.text('Corrigidas (demo)'), findsNothing);
      expect(valorMetrica(tester, 'Provas corrigidas'), '0');
      expect(valorMetrica(tester, 'Folhas corrigidas'), '0');

      expect(find.text('CORREÇÕES RECENTES'), findsOneWidget);
      expect(find.text('Demonstrativo'), findsNothing);
      expect(find.textContaining('Nenhuma prova corrigida ainda'), findsOneWidget);
    });

    testWidgets('4. ProfileScreen: exibe perfil real e contador de turmas real',
        (tester) async {
      final fakeAuth = FakeAuditoriaAuthService(
        usuarioInicial: Usuario(
          id: 'prof_456',
          nome: 'Maria Quitéria',
          email: 'maria.quiteria@escola.gov.br',
          instituicao: 'Instituto Histórico',
        ),
      );

      final fakeTurma = FakeTurmaService(initialUserId: 'prof_456');
      await fakeTurma.criarTurma(
        nome: 'Turma Alfa',
        ano: '3º Ano',
        disciplina: 'História',
        periodo: 'Noite',
      );
      await fakeTurma.criarTurma(
        nome: 'Turma Beta',
        ano: '3º Ano',
        disciplina: 'História',
        periodo: 'Noite',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            authService: fakeAuth,
            turmaService: fakeTurma,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prof. Ana Paula Santos'), findsNothing);
      expect(find.text('ana.santos@escola.edu.br'), findsNothing);
      expect(find.text('E.E. Prof. Antônio Lemos'), findsNothing);
      expect(find.text('AP'), findsNothing);

      expect(find.text('Maria Quitéria'), findsOneWidget);
      expect(find.text('maria.quiteria@escola.gov.br'), findsOneWidget);
      expect(find.text('Instituto Histórico'), findsOneWidget);
      expect(find.text('MQ'), findsOneWidget);

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets(
        '5. EditProfileScreen: atualiza nome e instituição no serviço e reflete na interface',
        (tester) async {
      final usuarioInicial = Usuario(
        id: 'prof_789',
        nome: 'Clarice Lispector',
        email: 'clarice@literatura.edu.br',
        instituicao: 'Faculdade de Letras',
      );

      final fakeAuth =
          FakeAuditoriaAuthService(usuarioInicial: usuarioInicial);

      await tester.pumpWidget(
        MaterialApp(
          home: EditProfileScreen(
            authService: fakeAuth,
            usuarioAtual: usuarioInicial,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CL'), findsOneWidget);

      final nomeField = find.widgetWithText(TextField, 'Clarice Lispector');
      await tester.enterText(nomeField, 'Clarice Lispector Souza');
      await tester.pumpAndSettle();

      expect(find.text('CS'), findsOneWidget);

      final escolaField = find.widgetWithText(TextField, 'Faculdade de Letras');
      await tester.enterText(escolaField, 'Universidade Nova');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar alterações'));
      await tester.pumpAndSettle();

      final perfilAtualizado = await fakeAuth.buscarPerfil('prof_789');
      expect(perfilAtualizado?.nome, equals('Clarice Lispector Souza'));
      expect(perfilAtualizado?.instituicao, equals('Universidade Nova'));
    });

    testWidgets(
        '6. Isolamento entre sessões: dados do Usuário A não vazam para o Usuário B',
        (tester) async {
      final fakeTurma = FakeTurmaService(initialUserId: 'user_A');
      final tA = await fakeTurma.criarTurma(
        nome: 'Turma Exclusiva do Professor A',
        ano: '1º Ano',
        disciplina: 'Biologia',
        periodo: 'Manhã',
      );
      await fakeTurma.cadastrarAluno(
        turmaId: tA.id,
        nome: 'Aluno Exclusivo A1',
        ra: 'RA_A1',
      );
      await fakeTurma.cadastrarAluno(
        turmaId: tA.id,
        nome: 'Aluno Exclusivo A2',
        ra: 'RA_A2',
      );

      final fakeAuth = FakeAuditoriaAuthService(
        usuarioInicial: Usuario(
          id: 'user_A',
          nome: 'Professor A',
          email: 'profA@escola.com',
          instituicao: 'Escola A',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            authService: fakeAuth,
            turmaService: fakeTurma,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Professor A'), findsOneWidget);
      expect(find.text('PA'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      fakeAuth.definirUsuario(
        Usuario(
          id: 'user_B',
          nome: 'Professora B',
          email: 'profB@escola.com',
          instituicao: 'Escola B',
        ),
      );
      fakeTurma.trocarUsuario('user_B');

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            authService: fakeAuth,
            turmaService: fakeTurma,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Professor A'), findsNothing);
      expect(find.text('PA'), findsNothing);
      expect(find.text('2'), findsNothing);

      expect(find.text('Professora B'), findsOneWidget);
      expect(find.text('PB'), findsOneWidget);
      expect(valorMetrica(tester, 'Alunos'), '0');
    });

    testWidgets(
        '7. Telas demonstrativas (Provas, Resultados, Questões, Correção) exibem identificação visual',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProvasScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Demonstrativo'), findsNothing);
      expect(find.text('Nenhuma prova criada'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(home: ResultadosScreen(resultadoService: FakeResultadoService())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Modo demonstrativo'), findsNothing);
      expect(find.text('Nenhuma prova corrigida ainda'), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: BancoQuestoesScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Modo demonstrativo'), findsNothing);
      expect(find.text('Nenhuma questão cadastrada'), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: CorrigirProvaScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Demonstrativo'), findsNothing);
      expect(find.text('Como funciona'), findsOneWidget);
    });
  });
}
