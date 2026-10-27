import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/prova.dart';
import '../models/resultado.dart';

/// Persiste e consulta os resultados das correções no Firestore:
/// - usuarios/{uid}/provas/{provaId}                    -> resumoResultado + gabaritoOficial
/// - usuarios/{uid}/provas/{provaId}/resultados/{alunoId} -> resultado individual
class ResultadoService {
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  ResultadoService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore =
          firestore ??
          (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null),
      _auth = auth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null);

  FirebaseFirestore get firestore {
    if (_firestore == null) {
      throw StateError('Firestore não foi inicializado.');
    }
    return _firestore;
  }

  String get currentUserId {
    final uid = _auth?.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Nenhum professor autenticado encontrado.');
    }
    return uid;
  }

  String _resolveUserId(String? userId) {
    if (userId != null && userId.isNotEmpty) return userId;
    return currentUserId;
  }

  CollectionReference<Map<String, dynamic>> _provasRef(String userId) {
    return firestore.collection('usuarios').doc(userId).collection('provas');
  }

  CollectionReference<Map<String, dynamic>> _resultadosRef(
    String userId,
    String provaId,
  ) {
    return _provasRef(userId).doc(provaId).collection('resultados');
  }

  /// Calcula as estatísticas da correção e grava tudo em um único batch.
  /// Corrigir a mesma prova de novo sobrescreve o resultado de cada aluno.
  Future<ResultadoProva> salvarCorrecao({
    required Prova prova,
    required List<String> gabarito,
    required List<ResultadoAluno> resultados,
    String? userId,
  }) async {
    final uid = _resolveUserId(userId);
    final provaRef = _provasRef(uid).doc(prova.id);

    // Junta com folhas corrigidas anteriormente, para o resumo refletir a turma toda.
    final anteriores = await _listarResultadosAlunos(uid, prova.id);
    final porAluno = <String, ResultadoAluno>{
      for (final r in anteriores) r.aluno.id: r,
      for (final r in resultados) r.aluno.id: r,
    };

    final resultado = ResultadoProva.calcular(
      prova: prova,
      gabarito: gabarito,
      porAluno: porAluno.values.toList(),
    );

    final batch = firestore.batch();
    batch.set(
      provaRef,
      prova
          .copyWith(
            gabaritoOficial: gabarito,
            resumoResultado: resultado.toFirestoreResumo(),
          )
          .toFirestore(),
      SetOptions(merge: true),
    );

    for (final r in resultados) {
      batch.set(
        _resultadosRef(uid, prova.id).doc(r.aluno.id),
        r.copyWith(provaId: prova.id, turmaId: prova.turma.id).toFirestore(),
      );
    }

    await batch.commit();
    return resultado;
  }

  Future<List<ResultadoAluno>> _listarResultadosAlunos(
    String uid,
    String provaId,
  ) async {
    final snap = await _resultadosRef(uid, provaId).get();
    return snap.docs.map((doc) => ResultadoAluno.fromFirestore(doc)).toList();
  }

  /// Escuta as provas já corrigidas do professor, com os resultados por aluno,
  /// da mais recente para a mais antiga.
  Stream<List<ResultadoProva>> monitorarResultados({String? userId}) {
    if (_firestore == null) return Stream.value(const []);
    try {
      final uid = _resolveUserId(userId);
      return _provasRef(uid).snapshots().asyncMap((snapshot) async {
        final resultados = <ResultadoProva>[];

        for (final doc in snapshot.docs) {
          final prova = Prova.fromFirestore(doc);
          final resumo = prova.resumoResultado;
          if (resumo == null) continue;

          final porAluno = await _listarResultadosAlunos(uid, prova.id)
            ..sort(
              (a, b) => a.aluno.nome.toLowerCase().compareTo(
                b.aluno.nome.toLowerCase(),
              ),
            );

          resultados.add(
            ResultadoProva.fromResumo(resumo, prova: prova, porAluno: porAluno),
          );
        }

        resultados.sort(
          (a, b) => b.prova.dataAplicacao.compareTo(a.prova.dataAplicacao),
        );
        return resultados;
      });
    } catch (e) {
      return Stream.error(e);
    }
  }
}
