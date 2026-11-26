import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prova_certa/models/alternativa.dart';
import 'package:prova_certa/models/prova.dart';
import 'package:prova_certa/models/questao.dart';
import 'package:prova_certa/models/turma.dart';
import 'package:prova_certa/services/prova_service.dart';

const _uid = 'prof';

Questao _questao(String id, String correta) => Questao(
  id: id,
  enunciado: 'Enunciado $id',
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

Prova _prova() => Prova(
  id: 'p1',
  nome: 'Prova Original',
  turma: Turma(
    id: 't1',
    nome: '1º A',
    ano: '1º Ano',
    disciplina: 'Biologia',
    periodo: 'Manhã',
    alunos: const [],
  ),
  dataAplicacao: DateTime(2026, 10, 1),
  quantidadeQuestoes: 2,
  questoes: [_questao('q1', 'A'), _questao('q2', 'C')],
  status: ProvaStatus.ativa,
  gabaritoOficial: const ['A', 'C'],
  resumoResultado: const {'totalFolhasCorrigidas': 2},
  criadoEm: DateTime(2026, 9, 1),
);

Future<(FakeFirebaseFirestore, ProvaService)> _cenario() async {
  final db = FakeFirebaseFirestore();
  final provaRef =
      db.collection('usuarios').doc(_uid).collection('provas').doc('p1');
  await provaRef.set({'id': 'p1', ..._prova().toFirestore()});
  await provaRef.collection('resultados').doc('a1').set({'nota': 10});
  await provaRef.collection('resultados').doc('a2').set({'nota': 5});
  return (db, ProvaService(firestore: db));
}

Future<int> _totalResultados(FakeFirebaseFirestore db) async => (await db
        .collection('usuarios/$_uid/provas/p1/resultados')
        .get())
    .docs
    .length;

void main() {
  test('atualiza os dados sem tocar nos resultados', () async {
    final (db, service) = await _cenario();
    final original = (await service.buscarProva('p1', userId: _uid))!;

    await service.atualizarProva(
      original.copyWith(nome: 'Novo nome'),
      userId: _uid,
    );

    final salva = (await service.buscarProva('p1', userId: _uid))!;
    expect(salva.nome, 'Novo nome');
    expect(salva.criadoEm, DateTime(2026, 9, 1));
    expect(salva.resumoResultado, isNotNull);
    expect(await _totalResultados(db), 2);
  });

  test('descarta resultados e resumo quando solicitado', () async {
    final (db, service) = await _cenario();
    final original = (await service.buscarProva('p1', userId: _uid))!;

    final retornada = await service.atualizarProva(
      original,
      descartarResultados: true,
      userId: _uid,
    );

    final salva = (await service.buscarProva('p1', userId: _uid))!;
    expect(retornada.resumoResultado, isNull);
    expect(salva.resumoResultado, isNull);
    expect(salva.criadoEm, DateTime(2026, 9, 1));
    expect(await _totalResultados(db), 0);
  });

  test('valida a prova antes de gravar', () async {
    final (_, service) = await _cenario();

    expect(
      () => service.atualizarProva(
        _prova().copyWith(nome: '  '),
        userId: _uid,
      ),
      throwsArgumentError,
    );
    expect(
      () => service.atualizarProva(_prova().copyWith(id: ''), userId: _uid),
      throwsArgumentError,
    );
  });
}
