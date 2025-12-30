import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/usuario_model.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();

  // Configurações OAuth2 do Gov.br
  // IMPORTANTE: Estas credenciais são exemplos. Você precisa registrar seu app em:
  // https://sso.acesso.gov.br/
  // ignore: unused_field
  static const String _clientId = 'SEU_CLIENT_ID_AQUI';
  // ignore: unused_field
  static const String _clientSecret = 'SEU_CLIENT_SECRET_AQUI';
  // ignore: unused_field
  static const String _redirectUri = 'comprovapp://callback';

  // URLs do Gov.br
  // ignore: unused_field
  static const String _authorizationEndpoint =
      'https://sso.acesso.gov.br/authorize';
  // ignore: unused_field
  static const String _tokenEndpoint =
      'https://sso.acesso.gov.br/token';
  // ignore: unused_field
  static const String _userInfoEndpoint =
      'https://sso.acesso.gov.br/userinfo';

  // Scopes necessários
  // ignore: unused_field
  static const List<String> _scopes = [
    'openid',
    'email',
    'profile',
    'govbr_cpf',
    'govbr_nome',
  ];

  Usuario? _usuarioAtual;

  Usuario? get usuarioAtual => _usuarioAtual;

  /// Verifica se o usuário está autenticado
  Future<bool> isAuthenticated() async {
    try {
      final userData = await _storage.read(key: 'user_data');
      if (userData == null) return false;

      final usuario = Usuario.fromJson(jsonDecode(userData));

      // Verifica se o token ainda é válido
      if (!usuario.tokenValido) {
        // Tenta renovar o token
        final renewed = await _renewToken(usuario);
        if (!renewed) {
          await logout();
          return false;
        }
      }

      _usuarioAtual = usuario;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Inicia o fluxo de autenticação OAuth2 com Gov.br
  ///
  /// NOTA: Esta é uma implementação simulada para demonstração.
  /// Em produção, você precisará:
  /// 1. Registrar seu app no Gov.br
  /// 2. Configurar deep links (comprovapp://callback)
  /// 3. Usar um package como flutter_web_auth ou oauth2
  Future<Usuario?> login() async {
    try {
      // SIMULAÇÃO: Em produção, use flutter_web_auth ou oauth2 package
      //
      // final result = await FlutterWebAuth.authenticate(
      //   url: _buildAuthUrl(),
      //   callbackUrlScheme: 'comprovapp',
      // );
      //
      // final code = Uri.parse(result).queryParameters['code'];
      // final tokenData = await _exchangeCodeForToken(code!);
      // final userInfo = await _getUserInfo(tokenData['access_token']);

      // SIMULAÇÃO: Dados de exemplo
      await Future.delayed(const Duration(seconds: 2));

      final usuario = Usuario(
        cpf: '12345678901',
        nome: 'João da Silva Santos',
        email: 'joao.silva@email.com',
        telefone: '(11) 98765-4321',
        dataNascimento: DateTime(1990, 5, 15),
        accessToken: 'fake_access_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'fake_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
        tokenExpiry: DateTime.now().add(const Duration(hours: 1)),
      );

      await _saveUserData(usuario);
      _usuarioAtual = usuario;

      return usuario;
    } catch (e) {
      throw Exception('Erro ao fazer login: $e');
    }
  }

  /// Faz logout e limpa os dados armazenados
  Future<void> logout() async {
    await _storage.delete(key: 'user_data');
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    _usuarioAtual = null;
  }

  /// Obtém os dados do usuário atual
  Future<Usuario?> getCurrentUser() async {
    if (_usuarioAtual != null) return _usuarioAtual;

    final userData = await _storage.read(key: 'user_data');
    if (userData == null) return null;

    _usuarioAtual = Usuario.fromJson(jsonDecode(userData));
    return _usuarioAtual;
  }

  /// Salva os dados do usuário de forma segura
  Future<void> _saveUserData(Usuario usuario) async {
    await _storage.write(
      key: 'user_data',
      value: jsonEncode(usuario.toJson()),
    );
    await _storage.write(
      key: 'access_token',
      value: usuario.accessToken,
    );
    if (usuario.refreshToken != null) {
      await _storage.write(
        key: 'refresh_token',
        value: usuario.refreshToken!,
      );
    }
  }

  /// Renova o token de acesso
  Future<bool> _renewToken(Usuario usuario) async {
    try {
      if (usuario.refreshToken == null) return false;

      // SIMULAÇÃO: Em produção, faça a requisição real
      //
      // final response = await http.post(
      //   Uri.parse(_tokenEndpoint),
      //   headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      //   body: {
      //     'grant_type': 'refresh_token',
      //     'refresh_token': usuario.refreshToken!,
      //     'client_id': _clientId,
      //     'client_secret': _clientSecret,
      //   },
      // );
      //
      // if (response.statusCode == 200) {
      //   final data = jsonDecode(response.body);
      //   // Atualizar tokens...
      // }

      await Future.delayed(const Duration(seconds: 1));

      // Simula renovação do token
      final novoUsuario = Usuario(
        cpf: usuario.cpf,
        nome: usuario.nome,
        email: usuario.email,
        telefone: usuario.telefone,
        dataNascimento: usuario.dataNascimento,
        foto: usuario.foto,
        accessToken: 'renewed_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: usuario.refreshToken,
        tokenExpiry: DateTime.now().add(const Duration(hours: 1)),
      );

      await _saveUserData(novoUsuario);
      _usuarioAtual = novoUsuario;

      return true;
    } catch (e) {
      return false;
    }
  }

  // Métodos auxiliares para implementação real (comentados)

  /*
  String _buildAuthUrl() {
    final params = {
      'response_type': 'code',
      'client_id': _clientId,
      'redirect_uri': _redirectUri,
      'scope': _scopes.join(' '),
      'state': _generateState(),
    };

    final uri = Uri.parse(_authorizationEndpoint);
    return uri.replace(queryParameters: params).toString();
  }

  String _generateState() {
    // Gerar estado aleatório para segurança
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<Map<String, dynamic>> _exchangeCodeForToken(String code) async {
    final response = await http.post(
      Uri.parse(_tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': _redirectUri,
        'client_id': _clientId,
        'client_secret': _clientSecret,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao obter token: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> _getUserInfo(String accessToken) async {
    final response = await http.get(
      Uri.parse(_userInfoEndpoint),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao obter dados do usuário: ${response.body}');
    }
  }
  */
}
