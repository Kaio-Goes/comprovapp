import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comprovapp/models/usuario_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream do usuário autenticado (Firebase)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Usuário atual do Firebase
  User? get currentUser => _auth.currentUser;

  /// Login com email e senha
  Future<Usuario> login({
    required String email,
    required String senha,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
    final uid = credential.user!.uid;
    return _buscarPerfil(uid);
  }

  /// Cadastro: cria conta no Firebase Auth e salva perfil no Firestore
  Future<Usuario> cadastrar({
    required String email,
    required String senha,
    required String nomeCompleto,
    required String cpf,
    required DateTime dataNascimento,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
    final uid = credential.user!.uid;

    await credential.user!.updateDisplayName(nomeCompleto);

    final usuario = Usuario(
      uid: uid,
      cpf: cpf.replaceAll(RegExp(r'[^\d]'), ''),
      nomeCompleto: nomeCompleto,
      email: email.trim(),
      dataNascimento: dataNascimento,
    );

    await _firestore
        .collection('usuarios')
        .doc(uid)
        .set(usuario.toFirestore());

    return usuario;
  }

  /// Busca perfil do Firestore pelo UID
  Future<Usuario> _buscarPerfil(String uid) async {
    final doc = await _firestore.collection('usuarios').doc(uid).get();
    if (!doc.exists) {
      throw Exception('Perfil não encontrado no Firestore.');
    }
    return Usuario.fromFirestore(doc.data()!, uid);
  }

  /// Retorna o perfil do usuário logado (null se não autenticado)
  Future<Usuario?> perfilAtual() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      return await _buscarPerfil(user.uid);
    } catch (_) {
      return null;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Enviar e-mail de redefinição de senha
  Future<void> recuperarSenha(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Verifica se há usuário logado
  Future<bool> isAuthenticated() async {
    return _auth.currentUser != null;
  }
}

