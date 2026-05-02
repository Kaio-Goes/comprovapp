import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario_model.dart';

/// Serviço de autenticação local por CPF + senha.
///
/// Não usa Gov.br. O usuário se autentica com CPF e uma senha
/// definida no primeiro acesso. Os dados ficam armazenados de
/// forma segura via [FlutterSecureStorage].
class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _prefKeyLembrarMe = 'lembrar_me_cpf';

  Usuario? _usuarioAtual;

  Usuario? get usuarioAtual => _usuarioAtual;

  /// Verifica se há uma sessão ativa salva.
  Future<bool> isAuthenticated() async {
    try {
      final userData = await _storage.read(key: 'user_data');
      if (userData == null) return false;
      _usuarioAtual = Usuario.fromJson(jsonDecode(userData));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Autentica o usuário com CPF + senha.
  Future<Usuario?> login({
    required String cpf,
    required String senha,
    bool lembrarMe = false,
  }) async {
    try {
      final cpfLimpo = cpf.replaceAll(RegExp(r'[^\d]'), '');
      if (cpfLimpo.length != 11) return null;

      final hashSalvo = await _storage.read(key: 'senha_$cpfLimpo');

      if (hashSalvo == null) {
        // Primeiro acesso: cria a senha
        await _criarSenha(cpfLimpo, senha);
      } else {
        // Valida senha
        if (_hashSenha(cpfLimpo, senha) != hashSalvo) return null;
      }

      final usuario = await _carregarOuCriarPerfil(cpfLimpo);

      if (lembrarMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKeyLembrarMe, cpfLimpo);
        await _salvarSessao(usuario);
      } else {
        await _storage.delete(key: 'user_data');
      }

      _usuarioAtual = usuario;
      return usuario;
    } catch (e) {
      return null;
    }
  }

  /// Faz logout e limpa a sessão persistida.
  Future<void> logout() async {
    await _storage.delete(key: 'user_data');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyLembrarMe);
    _usuarioAtual = null;
  }

  /// Retorna o usuário atual (em memória ou armazenado).
  Future<Usuario?> getCurrentUser() async {
    if (_usuarioAtual != null) return _usuarioAtual;
    final userData = await _storage.read(key: 'user_data');
    if (userData == null) return null;
    _usuarioAtual = Usuario.fromJson(jsonDecode(userData));
    return _usuarioAtual;
  }

  /// Altera a senha de um CPF já cadastrado.
  Future<bool> alterarSenha({
    required String cpf,
    required String senhaAtual,
    required String novaSenha,
  }) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'[^\d]'), '');
    final hashAtual = await _storage.read(key: 'senha_$cpfLimpo');
    if (hashAtual == null) return false;
    if (_hashSenha(cpfLimpo, senhaAtual) != hashAtual) return false;
    await _criarSenha(cpfLimpo, novaSenha);
    return true;
  }

  // ── privados ────────────────────────────────────────────────────────────

  String _hashSenha(String cpf, String senha) {
    final key = utf8.encode('$cpf:comprovapp:$senha');
    return sha256.convert(key).toString();
  }

  Future<void> _criarSenha(String cpf, String senha) async {
    await _storage.write(key: 'senha_$cpf', value: _hashSenha(cpf, senha));
  }

  Future<Usuario> _carregarOuCriarPerfil(String cpf) async {
    final userData = await _storage.read(key: 'perfil_$cpf');
    if (userData != null) {
      return Usuario.fromJson(jsonDecode(userData));
    }

    final usuario = Usuario(
      cpf: cpf,
      nome: 'Usuário ${cpf.substring(0, 3)}***',
      accessToken: _gerarTokenSessao(cpf),
      tokenExpiry: DateTime.now().add(const Duration(days: 30)),
    );

    await _storage.write(
      key: 'perfil_$cpf',
      value: jsonEncode(usuario.toJson()),
    );
    return usuario;
  }

  Future<void> _salvarSessao(Usuario usuario) async {
    await _storage.write(
      key: 'user_data',
      value: jsonEncode(usuario.toJson()),
    );
  }

  String _gerarTokenSessao(String cpf) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final data = utf8.encode('$cpf:$timestamp');
    return sha256.convert(data).toString();
  }
}
