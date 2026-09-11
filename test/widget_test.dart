import 'package:flutter_test/flutter_test.dart';

import 'package:prova_certa/main.dart';
import 'package:prova_certa/screens/banco_questoes_screen.dart';

void main() {
  testWidgets('abre na tela de login e entra na home', (tester) async {
    await tester.pumpWidget(const ProvaCertaApp());

    expect(find.text('AvaliaPro'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);

    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Turmas'), findsOneWidget);
    expect(find.text('Banco de Questões'), findsOneWidget);
    expect(find.text('Selecionar questões'), findsOneWidget);
  });

  testWidgets('banco de questões lista e filtra por dificuldade', (tester) async {
    await tester.pumpWidget(const ProvaCertaApp());

    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Banco de Questões'));
    await tester.pumpAndSettle();

    expect(find.text('10 questões encontradas'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChipFiltro, 'Difícil'));
    await tester.pumpAndSettle();

    expect(find.text('1 questão encontrada'), findsOneWidget);
  });
}
