import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/questao.dart';

class QuestaoService {
  static const minimoAlternativas = 2;
  static const maximoAlternativas = 5;

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  QuestaoService({
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

  CollectionReference<Map<String, dynamic>> _questoesRef(String userId) {
    return firestore.collection('usuarios').doc(userId).collection('questoes');
  }

  List<Questao> _ordenar(Iterable<Questao> questoes) {
    final lista = questoes.toList();
    lista.sort((a, b) {
      final dataA = a.criadoEm;
      final dataB = b.criadoEm;
      if (dataA == null && dataB == null) return 0;
      if (dataA == null) return 1;
      if (dataB == null) return -1;
      return dataA.compareTo(dataB);
    });
    return lista;
  }

  void _validar(Questao questao) {
    if (questao.enunciado.trim().isEmpty) {
      throw ArgumentError('O enunciado da questão é obrigatório.');
    }
    if (questao.assunto.trim().isEmpty) {
      throw ArgumentError('O assunto da questão é obrigatório.');
    }
    if (questao.dificuldade.trim().isEmpty) {
      throw ArgumentError('A dificuldade da questão é obrigatória.');
    }
    if (questao.disciplina.trim().isEmpty) {
      throw ArgumentError('A disciplina da questão é obrigatória.');
    }
    if (questao.alternativas.length < minimoAlternativas ||
        questao.alternativas.length > maximoAlternativas) {
      throw ArgumentError(
        'A questão deve ter entre $minimoAlternativas e '
        '$maximoAlternativas alternativas.',
      );
    }
    if (questao.alternativas.any((a) => a.texto.trim().isEmpty)) {
      throw ArgumentError('Todas as alternativas devem ser preenchidas.');
    }
    if (!questao.alternativas.any((a) => a.letra == questao.correta)) {
      throw ArgumentError('Selecione a alternativa correta.');
    }
  }

  Stream<List<Questao>> monitorarQuestoes({String? userId}) {
    if (_firestore == null) return const Stream.empty();
    try {
      final uid = _resolveUserId(userId);
      return _questoesRef(uid).snapshots().map((snapshot) =>
          _ordenar(snapshot.docs.map((doc) => Questao.fromFirestore(doc))));
    } catch (e) {
      return Stream.error(e);
    }
  }

  Future<List<Questao>> listarQuestoes({String? userId}) async {
    final uid = _resolveUserId(userId);
    final snapshot = await _questoesRef(uid).get();
    return _ordenar(snapshot.docs.map((doc) => Questao.fromFirestore(doc)));
  }

  Future<Questao?> buscarQuestao(String questaoId, {String? userId}) async {
    final uid = _resolveUserId(userId);
    final doc = await _questoesRef(uid).doc(questaoId).get();
    if (!doc.exists) return null;
    return Questao.fromFirestore(doc);
  }

  Future<Questao> criarQuestao(Questao questao, {String? userId}) async {
    _validar(questao);

    final uid = _resolveUserId(userId);
    final docRef = _questoesRef(uid).doc();
    final nova = questao.copyWith(id: docRef.id);

    await docRef.set({
      'id': docRef.id,
      ...nova.toFirestore(),
    });

    return nova.copyWith(
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );
  }

  Future<Questao> atualizarQuestao(Questao questao, {String? userId}) async {
    if (questao.id.isEmpty) {
      throw ArgumentError('Questão sem identificador para atualização.');
    }
    _validar(questao);

    final uid = _resolveUserId(userId);
    final dados = questao.toFirestore()..remove('criadoEm');

    await _questoesRef(uid).doc(questao.id).update(dados);

    return questao.copyWith(atualizadoEm: DateTime.now());
  }

  Future<void> excluirQuestao(String questaoId, {String? userId}) async {
    final uid = _resolveUserId(userId);
    await _questoesRef(uid).doc(questaoId).delete();
  }
}
