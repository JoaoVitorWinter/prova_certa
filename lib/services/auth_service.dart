import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/usuario.dart';

class AuthService {
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null),
        _firestore = firestore ??
            (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  FirebaseAuth get auth {
    if (_auth == null) {
      throw StateError('Firebase Auth não foi inicializado.');
    }
    return _auth;
  }

  FirebaseFirestore get firestore {
    if (_firestore == null) {
      throw StateError('Firestore não foi inicializado.');
    }
    return _firestore;
  }

  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

  User? get currentUser => _auth?.currentUser;
  String? get currentUserId => _auth?.currentUser?.uid;

  /// Realiza o login com e-mail e senha no Firebase Authentication
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Garante que o documento do professor exista no Firestore sem travar o login em caso de falha de rede
        try {
          await garantirDocumentoUsuario(user);
        } catch (e) {
          // Trata falha de Firestore separadamente da autenticação
          // ignore: avoid_print
          print('Aviso: Não foi possível sincronizar o perfil no Firestore: $e');
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _converterErroAuth(e);
    }
  }

  /// Realiza o cadastro de um novo professor no Auth e cria seu perfil em /usuarios/{uid}
  Future<User?> cadastrarProfessor({
    required String nome,
    required String email,
    required String instituicao,
    required String password,
  }) async {
    User? user;
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      user = credential.user;
      if (user == null) {
        throw 'Não foi possível criar a conta de usuário.';
      }
    } on FirebaseAuthException catch (e) {
      throw _converterErroAuth(e);
    }

    try {
      final docRef = firestore.collection('usuarios').doc(user.uid);
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        final novoUsuario = Usuario(
          id: user.uid,
          nome: nome.trim(),
          email: email.trim(),
          instituicao: instituicao.trim(),
          fotoUrl: user.photoURL,
        );
        await docRef.set(novoUsuario.toFirestore());
      }
      final confirmSnap = await docRef.get();
      if (!confirmSnap.exists || confirmSnap.data() == null) {
        throw StateError('Perfil não encontrado após gravação.');
      }
      try {
        await user.updateDisplayName(nome.trim());
      } catch (_) {}
      return user;
    } catch (_) {
      try {
        await user.delete();
      } catch (_) {}
      try {
        await _auth?.signOut();
      } catch (_) {}
      throw 'Não foi possível salvar os dados do perfil no Firestore. Tente novamente.';
    }
  }

  /// Envia e-mail de redefinição de senha oficial pelo Firebase Auth
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _converterErroAuth(e);
    }
  }

  /// Encerra a sessão atual
  Future<void> signOut() async {
    await _auth?.signOut();
  }

  /// Verifica e cria o documento do usuário em /usuarios/{uid} caso não exista
  Future<void> garantirDocumentoUsuario(User user) async {
    if (_firestore == null) return;
    final docRef = firestore.collection('usuarios').doc(user.uid);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      final nomePadrao =
          (user.displayName != null && user.displayName!.isNotEmpty)
              ? user.displayName!
              : (user.email != null && user.email!.contains('@')
                  ? user.email!.split('@').first
                  : 'Professor');

      await docRef.set({
        'id': user.uid,
        'nome': nomePadrao,
        'email': user.email ?? '',
        'instituicao': '',
        'fotoUrl': user.photoURL,
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Monitora os dados cadastrais do professor em tempo real
  Stream<Usuario?> monitorarPerfil(String uid) {
    if (_firestore == null) return const Stream.empty();
    return firestore.collection('usuarios').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Usuario.fromFirestore(doc);
    });
  }

  /// Atualiza os dados cadastrais do professor no Firestore e no Auth
  Future<void> atualizarPerfil({
    required String uid,
    required String nome,
    required String instituicao,
  }) async {
    if (_firestore == null) return;
    await firestore.collection('usuarios').doc(uid).update({
      'nome': nome.trim(),
      'instituicao': instituicao.trim(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
    try {
      await currentUser?.updateDisplayName(nome.trim());
    } catch (_) {}
  }

  /// Consulta os dados cadastrais do professor no Firestore
  Future<Usuario?> buscarPerfil(String uid) async {
    if (_firestore == null) return null;
    try {
      final docSnap = await firestore.collection('usuarios').doc(uid).get();
      if (!docSnap.exists || docSnap.data() == null) {
        return null;
      }
      return Usuario.fromFirestore(docSnap);
    } catch (_) {
      return null;
    }
  }

  /// Converte códigos de erro do Firebase Auth em mensagens amigáveis em português
  String _converterErroAuth(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Nenhum usuário encontrado com este e-mail.';
      case 'wrong-password':
        return 'Senha incorreta. Verifique suas credenciais.';
      case 'invalid-credential':
        return 'E-mail ou senha incorretos. Verifique suas credenciais.';
      case 'invalid-email':
        return 'O formato do e-mail informado é inválido.';
      case 'user-disabled':
        return 'Esta conta de professor foi desativada pelo administrador.';
      case 'too-many-requests':
        return 'Muitas tentativas consecutivas. Tente novamente mais tarde.';
      case 'network-request-failed':
        return 'Falha na conexão com a internet. Verifique sua rede.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado em outra conta.';
      case 'weak-password':
        return 'A senha escolhida é muito fraca. Utilize pelo menos 6 caracteres.';
      case 'operation-not-allowed':
        return 'O método de login por e-mail e senha não está habilitado no Firebase.';
      default:
        return e.message ?? 'Ocorreu um erro na autenticação. Tente novamente.';
    }
  }
}
