import 'package:firebase_auth/firebase_auth.dart';
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
  });
}
