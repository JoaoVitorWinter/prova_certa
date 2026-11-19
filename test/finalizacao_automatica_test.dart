import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prova_certa/models/aluno.dart';
import 'package:prova_certa/models/prova.dart';
import 'package:prova_certa/models/resultado.dart';
import 'package:prova_certa/models/turma.dart';
import 'package:prova_certa/services/prova_service.dart';
import 'package:prova_certa/services/resultado_service.dart';

const _uid = 'u1';
const _gabarito = ['A', 'B', 'C', 'D'];

final _ana = Aluno(id: 'a1', nome: 'Ana Souza', ra: '000123');
final _bruno = Aluno(id: 'a2', nome: 'Bruno Lima', ra: '000456');

Turma _turma() => Turma(
  id: 't1',
  nome: '1º A',
  ano: '1º Ano',
  disciplina: 'Biologia',
  periodo: 'Manhã',
  alunos: const [],
);

Prova _prova(ProvaStatus status) => Prova(
  id: 'p1',
  nome: 'Prova 1',
  turma: _turma(),
  dataAplicacao: DateTime(2026, 10, 20),
  quantidadeQuestoes: 4,
  questoes: const [],
  status: status,
);

ResultadoAluno _res(Aluno a, [List<String> r = _gabarito]) =>
    ResultadoAluno.corrigir(
      aluno: a,
      respostas: r,
      gabarito: _gabarito,
      provaId: 'p1',
    );

Future<(FakeFirebaseFirestore, ResultadoService, ProvaService)> _cenario({
  required ProvaStatus status,
  required List<Aluno> turma,
}) async {
  final db = FakeFirebaseFirestore();
  final turmaRef = db
      .collection('usuarios')
      .doc(_uid)
      .collection('turmas')
      .doc('t1');
  await turmaRef.set({'nome': '1º A'});
  for (final a in turma) {
    await turmaRef.collection('alunos').doc(a.id).set(a.toFirestore());
  }
  await db
      .collection('usuarios')
      .doc(_uid)
      .collection('provas')
      .doc('p1')
      .set(_prova(status).toFirestore());
  return (
    db,
    ResultadoService(firestore: db),
    ProvaService(firestore: db),
  );
}

Future<ProvaStatus> _status(ProvaService s) async =>
    (await s.buscarProva('p1', userId: _uid))!.status;

void main() {
  test('correção parcial mantém a prova ativa', () async {
    final (_, resultados, provas) = await _cenario(
      status: ProvaStatus.ativa,
      turma: [_ana, _bruno],
    );

    await resultados.salvarCorrecao(
      prova: _prova(ProvaStatus.ativa),
      gabarito: _gabarito,
      resultados: [_res(_ana)],
      userId: _uid,
    );

    expect(await _status(provas), ProvaStatus.ativa);
  });

  test('última correção encerra a prova junto com o resultado', () async {
    final (db, resultados, provas) = await _cenario(
      status: ProvaStatus.ativa,
      turma: [_ana, _bruno],
    );
    final prova = _prova(ProvaStatus.ativa);

    await resultados.salvarCorrecao(
      prova: prova,
      gabarito: _gabarito,
      resultados: [_res(_ana)],
      userId: _uid,
    );
    await resultados.salvarCorrecao(
      prova: prova,
      gabarito: _gabarito,
      resultados: [_res(_bruno, ['A', 'B', 'C', 'A'])],
      userId: _uid,
    );

    expect(await _status(provas), ProvaStatus.encerrada);
    final salvos = await db
        .collection('usuarios/$_uid/provas/p1/resultados')
        .get();
    expect(salvos.docs.map((d) => d.id).toSet(), {'a1', 'a2'});
    final doc = await provas.buscarProva('p1', userId: _uid);
    expect(doc!.resumoResultado!['totalFolhasCorrigidas'], 2);
  });

  test('turma vazia não encerra a prova', () async {
    final (_, resultados, provas) = await _cenario(
      status: ProvaStatus.ativa,
      turma: const [],
    );

    await resultados.salvarCorrecao(
      prova: _prova(ProvaStatus.ativa),
      gabarito: _gabarito,
      resultados: [_res(_ana)],
      userId: _uid,
    );

    expect(await _status(provas), ProvaStatus.ativa);
  });

  test('rascunho não é encerrado automaticamente', () async {
    final (_, resultados, provas) = await _cenario(
      status: ProvaStatus.rascunho,
      turma: [_ana],
    );

    await resultados.salvarCorrecao(
      prova: _prova(ProvaStatus.rascunho),
      gabarito: _gabarito,
      resultados: [_res(_ana)],
      userId: _uid,
    );

    expect(await _status(provas), ProvaStatus.rascunho);
  });

  test('recorreção não reabre prova encerrada nem altera o status', () async {
    final (_, resultados, provas) = await _cenario(
      status: ProvaStatus.ativa,
      turma: [_ana],
    );
    final prova = _prova(ProvaStatus.ativa);

    await resultados.salvarCorrecao(
      prova: prova,
      gabarito: _gabarito,
      resultados: [_res(_ana)],
      userId: _uid,
    );
    expect(await _status(provas), ProvaStatus.encerrada);

    // Recorreção com o objeto de prova defasado (ainda "ativa").
    final refeito = await resultados.salvarCorrecao(
      prova: prova,
      gabarito: _gabarito,
      resultados: [_res(_ana, ['B', 'B', 'C', 'D'])],
      userId: _uid,
    );
    expect(refeito.porAluno.single.acertos, 3);
    expect(await _status(provas), ProvaStatus.encerrada);
  });

  test('encerramento/reabertura manual continuam funcionando', () async {
    final (_, resultados, provas) = await _cenario(
      status: ProvaStatus.ativa,
      turma: [_ana, _bruno],
    );
    await resultados.salvarCorrecao(
      prova: _prova(ProvaStatus.ativa),
      gabarito: _gabarito,
      resultados: [_res(_ana)],
      userId: _uid,
    );

    await provas.atualizarStatus('p1', ProvaStatus.encerrada, userId: _uid);
    expect(await _status(provas), ProvaStatus.encerrada);
    await provas.atualizarStatus('p1', ProvaStatus.ativa, userId: _uid);
    expect(await _status(provas), ProvaStatus.ativa);
  });
}
