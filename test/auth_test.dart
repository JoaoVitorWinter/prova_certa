import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prova_certa/main.dart';
import 'package:prova_certa/screens/home_screen.dart';
import 'package:prova_certa/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prova_certa/screens/login_screen.dart';
import 'package:prova_certa/screens/reset_password_screen.dart';
import 'package:prova_certa/services/auth_service.dart';

class MockAuthService extends AuthService {
  final bool shouldFail;
  final String? errorToThrow;
  bool signInCalled = false;
  bool resetCalled = false;
  String? lastEmail;

  MockAuthService({this.shouldFail = false, this.errorToThrow});

  @override
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInCalled = true;
    lastEmail = email;
    if (shouldFail) {
      throw errorToThrow ?? 'E-mail ou senha incorretos.';
    }
    return null;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    resetCalled = true;
    lastEmail = email;
    if (shouldFail) {
      throw errorToThrow ?? 'Erro ao enviar e-mail.';
    }
  }

  bool registerCalled = false;
  String? lastNome;
  String? lastInstituicao;
  Completer<void>? registerCompleter;

  @override
  Future<User?> cadastrarProfessor({
    required String nome,
    required String email,
    required String instituicao,
    required String password,
  }) async {
    registerCalled = true;
    lastNome = nome;
    lastEmail = email;
    lastInstituicao = instituicao;
    if (registerCompleter != null) {
      await registerCompleter!.future;
    }
    if (shouldFail) {
      throw errorToThrow ?? 'Erro ao cadastrar.';
    }
    return null;
  }
}

class _FakeUser extends Fake implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  String? displayName;
  @override
  String? get photoURL => null;
  bool deleted = false;
  _FakeUser({required this.uid, required this.email});
  @override
  Future<void> updateDisplayName(String? name) async => displayName = name;
  @override
  Future<void> delete() async => deleted = true;
}

class _FakeCredential extends Fake implements UserCredential {
  @override
  final User? user;
  _FakeCredential(this.user);
}

class _FakeAuth extends Fake implements FirebaseAuth {
  final Map<String, _FakeUser> usersByEmail = {};
  final Map<String, String> passwordsByEmail = {};
  _FakeUser? _current;
  String? failCode;
  int _seq = 0;

  @override
  User? get currentUser => _current;

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (failCode != null) throw FirebaseAuthException(code: failCode!);
    if (usersByEmail.containsKey(email)) {
      throw FirebaseAuthException(code: 'email-already-in-use');
    }
    if (password.length < 6) {
      throw FirebaseAuthException(code: 'weak-password');
    }
    final u = _FakeUser(uid: 'uid_${++_seq}', email: email);
    usersByEmail[email] = u;
    passwordsByEmail[email] = password;
    _current = u;
    return _FakeCredential(u);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final u = usersByEmail[email];
    if (u == null || u.deleted || passwordsByEmail[email] != password) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    _current = u;
    return _FakeCredential(u);
  }

  @override
  Future<void> signOut() async => _current = null;
}

class _FakeFirestore extends Fake implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> docs = {};
  bool failOnWrite = false;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _FakeCol(this, path);
}

// ignore: subtype_of_sealed_class
class _FakeCol extends Fake implements CollectionReference<Map<String, dynamic>> {
  final _FakeFirestore db;
  @override
  final String path;
  _FakeCol(this.db, this.path);
  @override
  DocumentReference<Map<String, dynamic>> doc([String? id]) =>
      _FakeDoc(db, '$path/${id ?? "auto"}', id ?? 'auto');
}

// ignore: subtype_of_sealed_class
class _FakeDoc extends Fake implements DocumentReference<Map<String, dynamic>> {
  final _FakeFirestore db;
  final String fullPath;
  @override
  final String id;
  _FakeDoc(this.db, this.fullPath, this.id);
  @override
  CollectionReference<Map<String, dynamic>> collection(String sub) =>
      _FakeCol(db, '$fullPath/$sub');
  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    if (db.failOnWrite) throw Exception('Falha simulada no Firestore');
    final resolved = Map<String, dynamic>.from(data);
    for (final k in resolved.keys.toList()) {
      if (resolved[k] is FieldValue) resolved[k] = Timestamp.now();
    }
    db.docs[fullPath] = resolved;
  }
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? o]) async =>
      _FakeSnap(id, db.docs[fullPath]);
  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => Stream.value(_FakeSnap(id, db.docs[fullPath]));
}

// ignore: subtype_of_sealed_class
class _FakeSnap extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic>? _data;
  _FakeSnap(this.id, this._data);
  @override
  bool get exists => _data != null;
  @override
  Map<String, dynamic>? data() => _data;
}

void main() {
  group('Testes de Autenticação e Formulários', () {
    testWidgets('LoginScreen: exibe erro ao tentar submeter campos vazios',
        (tester) async {
      final mockAuth = MockAuthService();

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authService: mockAuth),
        ),
      );

      await tester.ensureVisible(find.text('Entrar'));
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(mockAuth.signInCalled, isFalse);
      expect(find.text('Informe o e-mail institucional.'), findsOneWidget);
    });

    testWidgets('LoginScreen: exibe erro com formato de e-mail inválido',
        (tester) async {
      final mockAuth = MockAuthService();

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authService: mockAuth),
        ),
      );

      await tester.enterText(
        find.byType(TextField).at(0),
        'email_invalido',
      );
      await tester.enterText(
        find.byType(TextField).at(1),
        '123456',
      );

      await tester.ensureVisible(find.text('Entrar'));
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(mockAuth.signInCalled, isFalse);
      expect(find.text('Informe um formato de e-mail válido.'), findsOneWidget);
    });

    testWidgets('LoginScreen: exibe mensagem quando autenticação falha',
        (tester) async {
      final mockAuth = MockAuthService(
        shouldFail: true,
        errorToThrow: 'Nenhum usuário encontrado com este e-mail.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authService: mockAuth),
        ),
      );

      await tester.enterText(
        find.byType(TextField).at(0),
        'inexistente@escola.edu.br',
      );
      await tester.enterText(
        find.byType(TextField).at(1),
        '123456',
      );

      await tester.ensureVisible(find.text('Entrar'));
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(mockAuth.signInCalled, isTrue);
      expect(
        find.text('Nenhum usuário encontrado com este e-mail.'),
        findsOneWidget,
      );
    });

    testWidgets('ResetPasswordScreen: valida e-mail e chama serviço oficial',
        (tester) async {
      final mockAuth = MockAuthService();

      await tester.pumpWidget(
        MaterialApp(
          home: ResetPasswordScreen(authService: mockAuth),
        ),
      );

      // 1. Tenta enviar sem e-mail
      await tester.ensureVisible(find.text('Enviar e-mail de recuperação'));
      await tester.tap(find.text('Enviar e-mail de recuperação'));
      await tester.pump();

      expect(mockAuth.resetCalled, isFalse);
      expect(find.text('Informe seu e-mail institucional.'), findsOneWidget);

      // 2. Preenche e-mail válido
      await tester.enterText(
        find.byType(TextField),
        'prof.recuperar@escola.edu.br',
      );
      await tester.tap(find.text('Enviar e-mail de recuperação'));
      await tester.pump();

      expect(mockAuth.resetCalled, isTrue);
      expect(mockAuth.lastEmail, equals('prof.recuperar@escola.edu.br'));
    });

    test(
        'AuthService.cadastrarProfessor: cria no Auth e Firestore (usuarios/{uid}), faz login/logout e isola professores',
        () async {
      final auth = _FakeAuth();
      final firestore = _FakeFirestore();
      final service = AuthService(auth: auth, firestore: firestore);

      final userA = await service.cadastrarProfessor(
        nome: '  Prof. Carlos Silva  ',
        email: '  carlos@escola.edu.br  ',
        instituicao: '  Colégio Estadual  ',
        password: 'senhaSegura123',
      );
      expect(userA, isNotNull);
      expect(auth.currentUser?.uid, equals(userA!.uid));

      final docSnapA = await firestore.collection('usuarios').doc(userA.uid).get();
      expect(docSnapA.exists, isTrue);
      expect(docSnapA.id, equals(userA.uid));
      final dataA = docSnapA.data()!;
      expect(dataA['nome'], equals('Prof. Carlos Silva'));
      expect(dataA['email'], equals('carlos@escola.edu.br'));
      expect(dataA['instituicao'], equals('Colégio Estadual'));
      expect(dataA['fotoUrl'], isNull);
      expect(dataA['criadoEm'], isA<Timestamp>());
      expect(dataA['atualizadoEm'], isA<Timestamp>());
      expect(dataA.containsKey('senha'), isFalse);
      expect(dataA.containsKey('password'), isFalse);
      expect(dataA.containsKey('hash'), isFalse);

      await service.signOut();
      expect(service.currentUser, isNull);

      final relogin = await service.signInWithEmailAndPassword(
        email: 'carlos@escola.edu.br',
        password: 'senhaSegura123',
      );
      expect(relogin?.uid, equals(userA.uid));
      expect(firestore.docs.keys.where((k) => k.startsWith('usuarios/')).length, 1);
      final perfilA = await service.buscarPerfil(userA.uid);
      expect(perfilA?.nome, equals('Prof. Carlos Silva'));
      expect(perfilA?.instituicao, equals('Colégio Estadual'));

      await service.signOut();
      final userB = await service.cadastrarProfessor(
        nome: 'Profa. Ana Souza',
        email: 'ana@instituto.edu.br',
        instituicao: 'Instituto Federal',
        password: 'senhaSegura456',
      );
      expect(userB!.uid, isNot(equals(userA.uid)));
      await firestore
          .collection('usuarios')
          .doc(userA.uid)
          .collection('turmas')
          .doc('t1')
          .set({'nome': 'Turma A'});
      final turmaB = await firestore
          .collection('usuarios')
          .doc(userB.uid)
          .collection('turmas')
          .doc('t1')
          .get();
      expect(turmaB.exists, isFalse);
    });

    test(
        'AuthService.cadastrarProfessor: trata erros do Auth e reverte conta se Firestore falhar',
        () async {
      final auth = _FakeAuth();
      final firestore = _FakeFirestore();
      final service = AuthService(auth: auth, firestore: firestore);

      await service.cadastrarProfessor(
        nome: 'Prof',
        email: 'duplicado@escola.edu.br',
        instituicao: 'Escola',
        password: '123456',
      );
      await expectLater(
        service.cadastrarProfessor(
          nome: 'Outro',
          email: 'duplicado@escola.edu.br',
          instituicao: 'Escola',
          password: '123456',
        ),
        throwsA('Este e-mail já está cadastrado em outra conta.'),
      );
      await expectLater(
        service.cadastrarProfessor(
          nome: 'Prof',
          email: 'fraca@escola.edu.br',
          instituicao: 'Escola',
          password: '123',
        ),
        throwsA(
          'A senha escolhida é muito fraca. Utilize pelo menos 6 caracteres.',
        ),
      );

      firestore.failOnWrite = true;
      await expectLater(
        service.cadastrarProfessor(
          nome: 'Prof Rollback',
          email: 'rollback@escola.edu.br',
          instituicao: 'Escola',
          password: '123456',
        ),
        throwsA(
          'Não foi possível salvar os dados do perfil no Firestore. Tente novamente.',
        ),
      );
      expect(auth.currentUser, isNull);
      expect(auth.usersByEmail['rollback@escola.edu.br']?.deleted, isTrue);
    });

    testWidgets(
        'RegisterScreen: valida campos, navega pelo Login e aguarda Firestore antes de abrir Home',
        (tester) async {
      final completer = Completer<void>();
      final mockAuth = MockAuthService()..registerCompleter = completer;

      await tester.pumpWidget(MaterialApp(home: LoginScreen(authService: mockAuth)));
      await tester.ensureVisible(find.text('Cadastre-se'));
      await tester.tap(find.text('Cadastre-se'));
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);

      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Criar conta'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Criar conta'));
      await tester.pump();
      expect(find.text('Informe o nome completo.'), findsOneWidget);
      ScaffoldMessenger.of(tester.element(find.byType(RegisterScreen))).removeCurrentSnackBar();
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), '  Profa. Helena  ');
      await tester.enterText(find.byType(TextField).at(1), '  helena@escola.edu.br  ');
      await tester.enterText(find.byType(TextField).at(2), '  Escola Central  ');
      await tester.enterText(find.byType(TextField).at(3), '123');
      await tester.enterText(find.byType(TextField).at(4), '123');
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Criar conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Criar conta'));
      await tester.pump();
      expect(find.text('A senha deve ter pelo menos 6 caracteres.'), findsOneWidget);
      ScaffoldMessenger.of(tester.element(find.byType(RegisterScreen))).removeCurrentSnackBar();
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(3), '123456');
      await tester.enterText(find.byType(TextField).at(4), '654321');
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Criar conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Criar conta'));
      await tester.pump();
      expect(find.text('As senhas informadas não coincidem.'), findsOneWidget);
      ScaffoldMessenger.of(tester.element(find.byType(RegisterScreen))).removeCurrentSnackBar();
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(4), '123456');
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Criar conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Criar conta'));
      await tester.pump();
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();
      expect(mockAuth.registerCalled, isTrue);
      expect(mockAuth.lastNome, equals('Profa. Helena'));
      expect(mockAuth.lastEmail, equals('helena@escola.edu.br'));
      expect(mockAuth.lastInstituicao, equals('Escola Central'));
      expect(find.byType(HomeScreen), findsOneWidget);

      final authReinicializacao = _FakeAuth();
      final dbReinicializacao = _FakeFirestore();
      final serviceReinicializacao = AuthService(
        auth: authReinicializacao,
        firestore: dbReinicializacao,
      );
      final userSemPerfil = _FakeUser(uid: 'u_orfao', email: 'orfao@escola.edu.br');
      await tester.pumpWidget(
        ProvaCertaApp(
          authStateStream: Stream.value(userSemPerfil),
          authService: serviceReinicializacao,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);

      final userComPerfil = await serviceReinicializacao.cadastrarProfessor(
        nome: 'Prof. Marcos',
        email: 'marcos@escola.edu.br',
        instituicao: 'Colégio Sul',
        password: '123456',
      );
      await tester.pumpWidget(
        ProvaCertaApp(
          authStateStream: Stream.value(userComPerfil),
          authService: serviceReinicializacao,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
