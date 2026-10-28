import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prova_certa/screens/reset_password_screen.dart';
import 'package:prova_certa/services/auth_service.dart';
import 'package:prova_certa/utils/validadores.dart';

class FakeRecuperacaoAuthService extends AuthService {
  final String codigoValido;
  String? emailEnviado;
  String? codigoVerificado;
  String? codigoConfirmado;
  String? senhaConfirmada;
  int enviosEmail = 0;

  FakeRecuperacaoAuthService({this.codigoValido = 'CODIGO_VALIDO_123'});

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    enviosEmail++;
    emailEnviado = email;
  }

  @override
  Future<String> verificarCodigoRedefinicao(String codigo) async {
    codigoVerificado = codigo;
    if (codigo != codigoValido) {
      throw 'O link ou código de recuperação é inválido ou já foi utilizado.';
    }
    return 'prof@escola.edu.br';
  }

  @override
  Future<void> confirmarRedefinicaoSenha({
    required String codigo,
    required String novaSenha,
  }) async {
    codigoConfirmado = codigo;
    senhaConfirmada = novaSenha;
  }
}

const linkRecuperacao =
    'https://provacerta-80ba5.firebaseapp.com/__/auth/action'
    '?mode=resetPassword&oobCode=CODIGO_VALIDO_123&apiKey=chave&lang=pt-BR';

Future<void> abrirTela(
  WidgetTester tester,
  FakeRecuperacaoAuthService service,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResetPasswordScreen(authService: service),
                ),
              ),
              child: const Text('Abrir recuperação'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir recuperação'));
  await tester.pumpAndSettle();
}

Future<void> tocar(WidgetTester tester, String texto) async {
  await tester.ensureVisible(find.text(texto));
  await tester.tap(find.text(texto));
  await tester.pump();
}

void limparMensagens(WidgetTester tester) {
  ScaffoldMessenger.of(
    tester.element(find.byType(ResetPasswordScreen)),
  ).removeCurrentSnackBar();
}

void main() {
  group('Validadores', () {
    test('e-mail', () {
      expect(Validadores.email(''), 'Informe o e-mail institucional.');
      expect(
        Validadores.email('prof@escola'),
        'Informe um formato de e-mail válido.',
      );
      expect(
        Validadores.email('prof@@escola.com'),
        'Informe um formato de e-mail válido.',
      );
      expect(Validadores.email('  prof.ana@escola.edu.br  '), isNull);
    });

    test('nova senha', () {
      expect(Validadores.novaSenha(''), 'Informe a senha de acesso.');
      expect(
        Validadores.novaSenha('abc12'),
        'A senha deve ter pelo menos 8 caracteres.',
      );
      expect(
        Validadores.novaSenha('abcdefgh'),
        'A senha deve conter letras e números.',
      );
      expect(
        Validadores.novaSenha('12345678'),
        'A senha deve conter letras e números.',
      );
      expect(
        Validadores.novaSenha(' senha123'),
        'A senha não pode começar nem terminar com espaço.',
      );
      expect(Validadores.novaSenha('senha123'), isNull);
    });

    test('confirmação de senha', () {
      expect(
        Validadores.confirmacaoSenha('senha123', ''),
        'Confirme a senha de acesso.',
      );
      expect(
        Validadores.confirmacaoSenha('senha123', 'senha124'),
        'As senhas informadas não coincidem.',
      );
      expect(Validadores.confirmacaoSenha('senha123', 'senha123'), isNull);
    });

    test('nome, instituição e RA', () {
      expect(Validadores.nomeCompleto(''), 'Informe o nome completo.');
      expect(
        Validadores.nomeCompleto('Jo'),
        'O nome deve ter pelo menos 3 caracteres.',
      );
      expect(Validadores.nomeCompleto('Ana 123'), isNotNull);
      expect(Validadores.nomeCompleto("Profa. Ana D'Ávila-Souza"), isNull);
      expect(Validadores.instituicao(''), 'Informe a instituição de ensino.');
      expect(Validadores.instituicao('', obrigatoria: false), isNull);
      expect(Validadores.ra(''), 'Informe o RA do aluno.');
      expect(Validadores.ra('12 34'), isNotNull);
      expect(Validadores.ra('2024-001/A'), isNull);
      expect(Validadores.nomeAluno('Mariana Rios'), isNull);
    });

    test('extrai o código do link de recuperação', () {
      expect(
        Validadores.extrairCodigoRedefinicao(linkRecuperacao),
        'CODIGO_VALIDO_123',
      );
      expect(
        Validadores.extrairCodigoRedefinicao('  CODIGO_VALIDO_123  '),
        'CODIGO_VALIDO_123',
      );
      expect(
        Validadores.extrairCodigoRedefinicao('https://exemplo.com/?mode=x'),
        isNull,
      );
      expect(Validadores.extrairCodigoRedefinicao('abc'), isNull);
      expect(
        Validadores.codigoRedefinicao(''),
        'Cole o link ou o código recebido por e-mail.',
      );
    });
  });

  group('ResetPasswordScreen', () {
    testWidgets('envia o e-mail e avança para a etapa do código',
        (tester) async {
      final service = FakeRecuperacaoAuthService();
      await abrirTela(tester, service);

      await tester.enterText(find.byType(TextField), 'prof@escola');
      await tocar(tester, 'Enviar e-mail de recuperação');
      expect(service.enviosEmail, 0);
      expect(find.text('Informe um formato de e-mail válido.'), findsOneWidget);
      limparMensagens(tester);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'prof@escola.edu.br');
      await tocar(tester, 'Enviar e-mail de recuperação');
      await tester.pumpAndSettle();

      expect(service.emailEnviado, 'prof@escola.edu.br');
      expect(find.text('Verifique seu e-mail'), findsOneWidget);
      expect(find.text('Reenviar e-mail em 60s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 61));
      expect(find.text('Reenviar e-mail'), findsOneWidget);

      await tocar(tester, 'Reenviar e-mail');
      await tester.pumpAndSettle();
      expect(service.enviosEmail, 2);
    });

    testWidgets('rejeita código inválido', (tester) async {
      final service = FakeRecuperacaoAuthService();
      await abrirTela(tester, service);

      await tocar(tester, 'Já recebi o e-mail');
      await tester.pumpAndSettle();

      await tocar(tester, 'Validar código');
      expect(
        find.text('Cole o link ou o código recebido por e-mail.'),
        findsOneWidget,
      );
      limparMensagens(tester);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'CODIGO_ERRADO_999');
      await tocar(tester, 'Validar código');
      await tester.pumpAndSettle();

      expect(service.codigoVerificado, 'CODIGO_ERRADO_999');
      expect(
        find.text(
          'O link ou código de recuperação é inválido ou já foi utilizado.',
        ),
        findsOneWidget,
      );
      expect(find.text('Crie uma nova senha'), findsNothing);
    });

    testWidgets('valida o link, exige senha forte e redefine a senha',
        (tester) async {
      final service = FakeRecuperacaoAuthService();
      await abrirTela(tester, service);

      await tocar(tester, 'Já recebi o e-mail');
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), linkRecuperacao);
      await tocar(tester, 'Validar código');
      await tester.pumpAndSettle();

      expect(service.codigoVerificado, 'CODIGO_VALIDO_123');
      expect(find.text('Crie uma nova senha'), findsOneWidget);
      expect(
        find.text('Defina a nova senha da conta prof@escola.edu.br.'),
        findsOneWidget,
      );

      final campos = find.byType(TextField);
      await tester.enterText(campos.at(0), 'fraca');
      await tester.enterText(campos.at(1), 'fraca');
      await tocar(tester, 'Redefinir senha');
      expect(
        find.text('A senha deve ter pelo menos 8 caracteres.'),
        findsOneWidget,
      );
      limparMensagens(tester);
      await tester.pumpAndSettle();

      await tester.enterText(campos.at(0), 'novaSenha123');
      await tester.enterText(campos.at(1), 'novaSenha124');
      await tocar(tester, 'Redefinir senha');
      expect(find.text('As senhas informadas não coincidem.'), findsOneWidget);
      expect(service.senhaConfirmada, isNull);
      limparMensagens(tester);
      await tester.pumpAndSettle();

      await tester.enterText(campos.at(1), 'novaSenha123');
      await tocar(tester, 'Redefinir senha');
      await tester.pumpAndSettle();

      expect(service.codigoConfirmado, 'CODIGO_VALIDO_123');
      expect(service.senhaConfirmada, 'novaSenha123');
      expect(find.byType(ResetPasswordScreen), findsNothing);
      expect(
        find.text('Senha redefinida com sucesso! Entre com a nova senha.'),
        findsOneWidget,
      );
    });

    testWidgets('voltar da etapa de nova senha retorna ao código',
        (tester) async {
      final service = FakeRecuperacaoAuthService();
      await abrirTela(tester, service);

      await tocar(tester, 'Já recebi o e-mail');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'CODIGO_VALIDO_123');
      await tocar(tester, 'Validar código');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Verifique seu e-mail'), findsOneWidget);
      expect(find.byType(ResetPasswordScreen), findsOneWidget);
    });
  });
}
