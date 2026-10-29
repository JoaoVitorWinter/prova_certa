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
        try {
          await garantirDocumentoUsuario(user);
        } catch (e) {
          print('Aviso: Não foi possível sincronizar o perfil no Firestore: $e');
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _converterErroAuth(e);
    }
  }

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

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _converterErroAuth(e);
    }
  }

  Future<String> verificarCodigoRedefinicao(String codigo) async {
    try {
      return await auth.verifyPasswordResetCode(codigo.trim());
    } on FirebaseAuthException catch (e) {
      throw _converterErroAuth(e);
    }
  }

  Future<void> confirmarRedefinicaoSenha({
    required String codigo,
    required String novaSenha,
  }) async {
    try {
      await auth.confirmPasswordReset(
        code: codigo.trim(),
        newPassword: novaSenha,
      );
    } on FirebaseAuthException catch (e) {
      throw _converterErroAuth(e);
    }
  }

  Future<void> signOut() async {
    await _auth?.signOut();
  }

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

  Stream<Usuario?> monitorarPerfil(String uid) {
    if (_firestore == null) return const Stream.empty();
    return firestore.collection('usuarios').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Usuario.fromFirestore(doc);
    });
  }

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
        return 'A senha escolhida é muito fraca. Use pelo menos 8 caracteres com letras e números.';
      case 'operation-not-allowed':
        return 'O método de login por e-mail e senha não está habilitado no Firebase.';
      case 'expired-action-code':
        return 'O link de recuperação expirou. Solicite um novo e-mail.';
      case 'invalid-action-code':
        return 'O link ou código de recuperação é inválido ou já foi utilizado.';
      case 'missing-email':
        return 'Informe o e-mail institucional.';
      default:
        return e.message ?? 'Ocorreu um erro na autenticação. Tente novamente.';
    }
  }
}
