import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/prova.dart';

class ProvaService {
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  ProvaService({
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

  CollectionReference<Map<String, dynamic>> _provasRef(String userId) {
    return firestore.collection('usuarios').doc(userId).collection('provas');
  }

  List<Prova> _ordenar(Iterable<Prova> provas) {
    final lista = provas.toList();
    lista.sort((a, b) => b.dataAplicacao.compareTo(a.dataAplicacao));
    return lista;
  }

  void _validar(Prova prova) {
    if (prova.nome.trim().isEmpty) {
      throw ArgumentError('O nome da prova é obrigatório.');
    }
    if (prova.turma.id.isEmpty) {
      throw ArgumentError('Selecione a turma da prova.');
    }
    if (prova.extrairQuestoesIds().isEmpty) {
      throw ArgumentError('Selecione ao menos uma questão.');
    }
    if (prova.quantidadeQuestoes != prova.extrairQuestoesIds().length) {
      throw ArgumentError(
        'A quantidade de questões não confere com as questões selecionadas.',
      );
    }
  }

  Stream<List<Prova>> monitorarProvas({String? userId}) {
    if (_firestore == null) return const Stream.empty();
    try {
      final uid = _resolveUserId(userId);
      return _provasRef(uid).snapshots().map((snapshot) =>
          _ordenar(snapshot.docs.map((doc) => Prova.fromFirestore(doc))));
    } catch (e) {
      return Stream.error(e);
    }
  }

  Future<List<Prova>> listarProvas({String? userId}) async {
    final uid = _resolveUserId(userId);
    final snapshot = await _provasRef(uid).get();
    return _ordenar(snapshot.docs.map((doc) => Prova.fromFirestore(doc)));
  }

  Future<Prova?> buscarProva(String provaId, {String? userId}) async {
    final uid = _resolveUserId(userId);
    final doc = await _provasRef(uid).doc(provaId).get();
    if (!doc.exists) return null;
    return Prova.fromFirestore(doc);
  }

  Future<Prova> criarProva(Prova prova, {String? userId}) async {
    _validar(prova);

    final uid = _resolveUserId(userId);
    final docRef = _provasRef(uid).doc();
    final nova = prova.copyWith(id: docRef.id);

    await docRef.set({
      'id': docRef.id,
      ...nova.toFirestore(),
    });

    return nova.copyWith(
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );
  }

  Future<void> atualizarStatus(
    String provaId,
    ProvaStatus status, {
    String? userId,
  }) async {
    final uid = _resolveUserId(userId);
    await _provasRef(uid).doc(provaId).update({
      'status': status.name,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> excluirProva(String provaId, {String? userId}) async {
    final uid = _resolveUserId(userId);
    final provaRef = _provasRef(uid).doc(provaId);
    final resultados = await provaRef.collection('resultados').get();
    for (final doc in resultados.docs) {
      await doc.reference.delete();
    }
    await provaRef.delete();
  }
}
