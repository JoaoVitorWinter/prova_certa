import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prova_certa/main.dart';
import 'package:prova_certa/screens/banco_questoes_screen.dart';
import 'package:prova_certa/screens/home_screen.dart';
import 'package:prova_certa/screens/login_screen.dart';
import 'package:prova_certa/services/auth_service.dart';

class FakeAuthService extends AuthService {
  final bool shouldFail;
  final String? errorMessage;
  bool loginCalled = false;

  FakeAuthService({this.shouldFail = false, this.errorMessage});

  @override
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    loginCalled = true;
    if (shouldFail) {
      throw errorMessage ?? 'E-mail ou senha incorretos.';
    }
    return null;
  }
}

void main() {
  testWidgets('abre na tela de login e entra na home com credenciais válidas',
      (tester) async {
    final fakeAuth = FakeAuthService();

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(authService: fakeAuth),
      ),
    );

    expect(find.text('AvaliaPro'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);

    // Preenche credenciais válidas
    await tester.enterText(
      find.byType(TextField).at(0),
      'professor@escola.edu.br',
    );
    await tester.enterText(
      find.byType(TextField).at(1),
      '123456',
    );

    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(fakeAuth.loginCalled, isTrue);
    expect(find.text('Criar prova'), findsOneWidget);
    expect(find.text('Banco de questões'), findsOneWidget);
  });

  testWidgets('home abre o banco de questões', (tester) async {
    await tester.pumpWidget(
      const ProvaCertaApp(homeOverride: HomeScreen()),
    );

    await tester.ensureVisible(find.text('Banco de questões'));
    await tester.tap(find.text('Banco de questões'));
    await tester.pumpAndSettle();

    expect(find.byType(BancoQuestoesScreen), findsOneWidget);
  });
}
