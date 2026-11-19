import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:prova_certa/models/alternativa.dart';
import 'package:prova_certa/models/questao.dart';
import 'package:prova_certa/models/turma.dart';
import 'package:prova_certa/services/geracao_pdf_prova_service.dart';
import 'package:prova_certa/services/geracao_versoes_service.dart';
import 'package:prova_certa/models/prova.dart';

Questao _questao(String id, String correta) {
  return Questao(
    id: id,
    enunciado: 'Enunciado $id',
    alternativas: [
      Alternativa(letra: 'A', texto: 'Alternativa A'),
      Alternativa(letra: 'B', texto: 'Alternativa B'),
      Alternativa(letra: 'C', texto: 'Alternativa C'),
      Alternativa(letra: 'D', texto: 'Alternativa D'),
    ],
    correta: correta,
    assunto: 'Geral',
    dificuldade: 'Fácil',
    disciplina: 'Geral',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final questoes = [
    _questao('q1', 'A'),
    _questao('q2', 'B'),
    _questao('q3', 'C'),
  ];

  test('gera no máximo quatro versões com gabaritos correspondentes', () {
    final versoes = GeracaoVersoesService().gerarVersoes(
      questoes: questoes,
      embaralharQuestoes: true,
      embaralharAlternativas: true,
      numeroVersoes: 4,
    );

    expect(versoes, hasLength(4));
    expect(versoes.map((versao) => versao.numero), [1, 2, 3, 4]);
    for (final versao in versoes) {
      expect(versao.questoes, hasLength(3));
      expect(versao.gabarito, [
        for (final questao in versao.questoes) questao.correta,
      ]);
    }
  });

  test('rejeita mais de quatro versões', () {
    expect(
      () => GeracaoVersoesService().gerarVersoes(
        questoes: questoes,
        embaralharQuestoes: false,
        embaralharAlternativas: false,
        numeroVersoes: 5,
      ),
      throwsArgumentError,
    );
  });

  test('serializa e restaura as versões da prova', () {
    final versoes = GeracaoVersoesService().gerarVersoes(
      questoes: questoes,
      embaralharQuestoes: false,
      embaralharAlternativas: true,
      numeroVersoes: 2,
    );
    final turma = Turma(
      id: 'turma',
      nome: 'Turma',
      ano: '2026',
      disciplina: 'Geral',
      periodo: 'Manhã',
      alunos: const [],
    );
    final prova = Prova(
      id: 'prova',
      nome: 'Avaliação',
      turma: turma,
      dataAplicacao: DateTime(2026, 11, 12),
      quantidadeQuestoes: questoes.length,
      questoes: questoes,
      status: ProvaStatus.ativa,
      numeroVersoes: 2,
      versoes: versoes,
      gabaritoOficial: ['A', 'B', 'C'],
    );

    final restaurada = Prova.fromMap(prova.toMap());

    expect(restaurada.versoes, isNotNull);
    expect(restaurada.versoes, hasLength(2));
    expect(restaurada.versoes!.last.gabarito, versoes.last.gabarito);
  });

  test('gera PDF A4 com caderno e folha de respostas', () async {
    final turma = Turma(
      id: 'turma',
      nome: 'Turma',
      ano: '2026',
      disciplina: 'Geral',
      periodo: 'Manhã',
      alunos: const [],
    );
    final prova = Prova(
      id: 'prova',
      nome: 'Avaliação',
      turma: turma,
      dataAplicacao: DateTime(2026, 11, 12),
      quantidadeQuestoes: questoes.length,
      questoes: questoes,
      status: ProvaStatus.ativa,
      gabaritoOficial: ['A', 'B', 'C'],
    );

    final pdf = await GeracaoPdfProvaService().gerar(prova: prova);

    expect(pdf, isA<Uint8List>());
    expect(pdf.take(4), orderedEquals([37, 80, 68, 70]));
    expect(pdf.length, greaterThan(1000));
  });
}
