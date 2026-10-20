import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/aluno.dart';
import '../models/turma.dart';

class TurmaService {
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  TurmaService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ??
            (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null),
        _auth = auth ??
            (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null);

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

  CollectionReference<Map<String, dynamic>> _turmasRef(String userId) {
    return firestore.collection('usuarios').doc(userId).collection('turmas');
  }

  CollectionReference<Map<String, dynamic>> _alunosRef(
    String userId,
    String turmaId,
  ) {
    return _turmasRef(userId).doc(turmaId).collection('alunos');
  }

  // =========================================================================
  // GESTÃO DE TURMAS
  // =========================================================================

  /// Escuta em tempo real a lista de turmas do professor autenticado
  Stream<List<Turma>> monitorarTurmas({String? userId}) {
    if (_firestore == null) return const Stream.empty();
    try {
      final uid = _resolveUserId(userId);
      return _turmasRef(uid)
          .orderBy('nome')
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => Turma.fromFirestore(doc)).toList())
          .handleError((_) {
        // Fallback caso a ordenação necessite de índice não sincronizado
        return _turmasRef(uid).snapshots().map((snapshot) =>
            snapshot.docs.map((doc) => Turma.fromFirestore(doc)).toList());
      });
    } catch (e) {
      return Stream.error(e);
    }
  }

  /// Consulta pontual de todas as turmas do professor
  Future<List<Turma>> listarTurmas({String? userId}) async {
    final uid = _resolveUserId(userId);
    final snapshot = await _turmasRef(uid).get();
    return snapshot.docs.map((doc) => Turma.fromFirestore(doc)).toList();
  }

  /// Escuta em tempo real os dados de uma única turma
  Stream<Turma?> monitorarTurma(String turmaId, {String? userId}) {
    if (_firestore == null) return const Stream.empty();
    try {
      final uid = _resolveUserId(userId);
      return _turmasRef(uid).doc(turmaId).snapshots().map((doc) {
        if (!doc.exists) return null;
        return Turma.fromFirestore(doc);
      });
    } catch (e) {
      return Stream.error(e);
    }
  }

  /// Consulta pontual de uma turma específica
  Future<Turma?> buscarTurma(String turmaId, {String? userId}) async {
    final uid = _resolveUserId(userId);
    final doc = await _turmasRef(uid).doc(turmaId).get();
    if (!doc.exists) return null;
    return Turma.fromFirestore(doc);
  }

  /// Cria uma nova turma associada ao professor autenticado
  Future<Turma> criarTurma({
    required String nome,
    required String ano,
    required String disciplina,
    required String periodo,
    String? userId,
  }) async {
    final nomeLimpo = nome.trim();
    final anoLimpo = ano.trim();
    final disciplinaLimpa = disciplina.trim();
    final periodoLimpo = periodo.trim();

    if (nomeLimpo.isEmpty) {
      throw ArgumentError('O nome da turma é obrigatório.');
    }
    if (anoLimpo.isEmpty) {
      throw ArgumentError('O ano da turma é obrigatório.');
    }
    if (disciplinaLimpa.isEmpty) {
      throw ArgumentError('A disciplina da turma é obrigatória.');
    }
    if (periodoLimpo.isEmpty) {
      throw ArgumentError('O período/turno da turma é obrigatório.');
    }

    final uid = _resolveUserId(userId);
    final docRef = _turmasRef(uid).doc();

    final dados = {
      'id': docRef.id,
      'nome': nomeLimpo,
      'ano': anoLimpo,
      'disciplina': disciplinaLimpa,
      'periodo': periodoLimpo,
      'quantidadeAlunos': 0,
      'criadoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    };

    await docRef.set(dados);

    return Turma(
      id: docRef.id,
      nome: nomeLimpo,
      ano: anoLimpo,
      disciplina: disciplinaLimpa,
      periodo: periodoLimpo,
      alunos: const [],
      quantidadeAlunos: 0,
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );
  }

  /// Atualiza os dados cadastrais da turma
  Future<void> atualizarTurma({
    required String turmaId,
    required String nome,
    required String ano,
    required String disciplina,
    required String periodo,
    String? userId,
  }) async {
    final nomeLimpo = nome.trim();
    final anoLimpo = ano.trim();
    final disciplinaLimpa = disciplina.trim();
    final periodoLimpo = periodo.trim();

    if (nomeLimpo.isEmpty) {
      throw ArgumentError('O nome da turma é obrigatório.');
    }
    if (anoLimpo.isEmpty) {
      throw ArgumentError('O ano da turma é obrigatório.');
    }
    if (disciplinaLimpa.isEmpty) {
      throw ArgumentError('A disciplina da turma é obrigatória.');
    }
    if (periodoLimpo.isEmpty) {
      throw ArgumentError('O período/turno da turma é obrigatório.');
    }

    final uid = _resolveUserId(userId);
    await _turmasRef(uid).doc(turmaId).update({
      'nome': nomeLimpo,
      'ano': anoLimpo,
      'disciplina': disciplinaLimpa,
      'periodo': periodoLimpo,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Exclui uma turma e seus respectivos alunos
  Future<void> excluirTurma(String turmaId, {String? userId}) async {
    final uid = _resolveUserId(userId);
    final alunosSnap = await _alunosRef(uid, turmaId).get();
    for (final doc in alunosSnap.docs) {
      await doc.reference.delete();
    }
    await _turmasRef(uid).doc(turmaId).delete();
  }

  // =========================================================================
  // GESTÃO DE ALUNOS (SUBCOLEÇÃO /alunos)
  // =========================================================================

  /// Escuta em tempo real os alunos cadastrados na turma
  Stream<List<Aluno>> monitorarAlunos({
    required String turmaId,
    String? userId,
  }) {
    if (_firestore == null) return const Stream.empty();
    try {
      final uid = _resolveUserId(userId);
      return _alunosRef(uid, turmaId)
          .orderBy('nome')
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => Aluno.fromFirestore(doc)).toList())
          .handleError((_) {
        return _alunosRef(uid, turmaId).snapshots().map((snapshot) =>
            snapshot.docs.map((doc) => Aluno.fromFirestore(doc)).toList());
      });
    } catch (e) {
      return Stream.error(e);
    }
  }

  /// Consulta pontual dos alunos cadastrados na turma
  Future<List<Aluno>> listarAlunos({
    required String turmaId,
    String? userId,
  }) async {
    final uid = _resolveUserId(userId);
    final snap = await _alunosRef(uid, turmaId).get();
    return snap.docs.map((doc) => Aluno.fromFirestore(doc)).toList();
  }

  /// Cadastra um aluno manualmente na turma com validação de RA e incremento atômico
  Future<Aluno> cadastrarAluno({
    required String turmaId,
    required String nome,
    required String ra,
    String? userId,
  }) async {
    final nomeLimpo = nome.trim();
    final raLimpo = ra.trim();

    if (nomeLimpo.isEmpty) {
      throw ArgumentError('O nome do aluno é obrigatório.');
    }
    if (raLimpo.isEmpty) {
      throw ArgumentError('O RA do aluno é obrigatório.');
    }

    final uid = _resolveUserId(userId);

    // Verificação de RA duplicado na mesma turma
    final duplicado = await _alunosRef(uid, turmaId)
        .where('ra', isEqualTo: raLimpo)
        .limit(1)
        .get();

    if (duplicado.docs.isNotEmpty) {
      throw Exception(
        'Já existe um aluno cadastrado com o RA "$raLimpo" nesta turma.',
      );
    }

    final turmaRef = _turmasRef(uid).doc(turmaId);
    final alunoRef = _alunosRef(uid, turmaId).doc();

    await firestore.runTransaction((transaction) async {
      final turmaDoc = await transaction.get(turmaRef);
      if (!turmaDoc.exists) {
        throw Exception('Turma não encontrada para cadastro de aluno.');
      }

      final qtdAtual =
          (turmaDoc.data()?['quantidadeAlunos'] as num?)?.toInt() ?? 0;
      final novaQtd = qtdAtual + 1;

      transaction.set(alunoRef, {
        'id': alunoRef.id,
        'nome': nomeLimpo,
        'ra': raLimpo,
        'turmaId': turmaId,
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      transaction.update(turmaRef, {
        'quantidadeAlunos': novaQtd,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    });

    return Aluno(
      id: alunoRef.id,
      nome: nomeLimpo,
      ra: raLimpo,
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );
  }

  /// Edita nome ou RA do aluno mantendo a unicidade do RA na turma
  Future<void> editarAluno({
    required String turmaId,
    required String alunoId,
    required String nome,
    required String ra,
    String? userId,
  }) async {
    final nomeLimpo = nome.trim();
    final raLimpo = ra.trim();

    if (nomeLimpo.isEmpty) {
      throw ArgumentError('O nome do aluno é obrigatório.');
    }
    if (raLimpo.isEmpty) {
      throw ArgumentError('O RA do aluno é obrigatório.');
    }

    final uid = _resolveUserId(userId);

    // Verificação de duplicação de RA com outro aluno da turma
    final existentes = await _alunosRef(uid, turmaId)
        .where('ra', isEqualTo: raLimpo)
        .get();

    for (final doc in existentes.docs) {
      if (doc.id != alunoId) {
        throw Exception(
          'Já existe outro aluno cadastrado com o RA "$raLimpo" nesta turma.',
        );
      }
    }

    await _alunosRef(uid, turmaId).doc(alunoId).update({
      'nome': nomeLimpo,
      'ra': raLimpo,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Remove um aluno da turma e atualiza a contagem de forma atômica
  Future<void> removerAluno({
    required String turmaId,
    required String alunoId,
    String? userId,
  }) async {
    final uid = _resolveUserId(userId);
    final turmaRef = _turmasRef(uid).doc(turmaId);
    final alunoRef = _alunosRef(uid, turmaId).doc(alunoId);

    await firestore.runTransaction((transaction) async {
      final turmaDoc = await transaction.get(turmaRef);
      final alunoDoc = await transaction.get(alunoRef);

      if (alunoDoc.exists) {
        transaction.delete(alunoRef);
        final qtdAtual =
            (turmaDoc.data()?['quantidadeAlunos'] as num?)?.toInt() ?? 0;
        final novaQtd = qtdAtual > 0 ? qtdAtual - 1 : 0;

        transaction.update(turmaRef, {
          'quantidadeAlunos': novaQtd,
          'atualizadoEm': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
