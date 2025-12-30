# Guia de Configuração Gov.br OAuth2

## 📋 Pré-requisitos

1. Conta no Gov.br (nível prata ou ouro)
2. Aplicativo mobile publicado ou em desenvolvimento
3. Domínio ou URL de callback

## 🔧 Passo a Passo: Registrar Aplicativo no Gov.br

### 1. Acessar o Portal de Serviços

1. Acesse: https://sso.acesso.gov.br/
2. Faça login com sua conta Gov.br
3. Vá para "Meus Aplicativos" ou "Cadastrar Aplicativo"

### 2. Dados do Aplicativo

Preencha as informações:

```
Nome do Aplicativo: ComprovApp
Descrição: Aplicativo para gerenciamento de notas fiscais eletrônicas
Tipo: Mobile (Android/iOS)
URL de Callback/Redirect URI: comprovapp://callback
Scopes/Permissões necessárias:
  - openid (obrigatório)
  - email
  - profile
  - govbr_cpf
  - govbr_nome
```

### 3. Obter Credenciais

Após o cadastro, você receberá:

```
Client ID: xxxxx-xxxxx-xxxxx-xxxxx
Client Secret: yyyyyy-yyyyyy-yyyyyy-yyyyyy
```

⚠️ **IMPORTANTE**: Guarde essas credenciais em local seguro!

## 🔐 Configurar Credenciais no App

### Método 1: Variáveis de Ambiente (Recomendado)

1. Crie um arquivo `lib/config/env.dart`:

```dart
class Env {
  static const String govbrClientId = String.fromEnvironment(
    'GOVBR_CLIENT_ID',
    defaultValue: 'SEU_CLIENT_ID_AQUI',
  );

  static const String govbrClientSecret = String.fromEnvironment(
    'GOVBR_CLIENT_SECRET',
    defaultValue: 'SEU_CLIENT_SECRET_AQUI',
  );
}
```

2. Execute o app com variáveis:
```bash
flutter run --dart-define=GOVBR_CLIENT_ID=seu_id \
           --dart-define=GOVBR_CLIENT_SECRET=seu_secret
```

### Método 2: Arquivo de Configuração (Desenvolvimento)

1. Crie `lib/config/secrets.dart` (adicione ao .gitignore):

```dart
class Secrets {
  static const String govbrClientId = 'seu_client_id_aqui';
  static const String govbrClientSecret = 'seu_client_secret_aqui';
}
```

2. Adicione ao `.gitignore`:
```
lib/config/secrets.dart
```

3. Use em `auth_service.dart`:
```dart
import '../config/secrets.dart';

class AuthService {
  static const String _clientId = Secrets.govbrClientId;
  static const String _clientSecret = Secrets.govbrClientSecret;
  // ...
}
```

## 📱 Configurar Deep Links

### Android

1. Edite `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <activity
            android:name=".MainActivity"
            android:launchMode="singleTop">

            <!-- Deep Link para OAuth Callback -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data
                    android:scheme="comprovapp"
                    android:host="callback" />
            </intent-filter>

        </activity>
    </application>
</manifest>
```

### iOS

1. Edite `ios/Runner/Info.plist`:

```xml
<plist version="1.0">
<dict>
    <!-- Outros configs... -->

    <!-- Deep Link para OAuth Callback -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>comprovapp</string>
            </array>
        </dict>
    </array>

</dict>
</plist>
```

## 🔨 Implementar OAuth2 Real

### 1. Instalar Package

Adicione ao `pubspec.yaml`:
```yaml
dependencies:
  flutter_web_auth: ^0.5.0
  # ou
  oauth2: ^2.0.2
```

### 2. Atualizar AuthService

Edite `lib/services/auth_service.dart`:

```dart
import 'package:flutter_web_auth/flutter_web_auth.dart';

class AuthService {
  // ... configurações existentes ...

  Future<Usuario?> login() async {
    try {
      // 1. Construir URL de autorização
      final authUrl = _buildAuthUrl();

      // 2. Abrir navegador para login
      final result = await FlutterWebAuth.authenticate(
        url: authUrl,
        callbackUrlScheme: 'comprovapp',
      );

      // 3. Extrair código do callback
      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) throw Exception('Código não recebido');

      // 4. Trocar código por token
      final tokenData = await _exchangeCodeForToken(code);

      // 5. Obter informações do usuário
      final userInfo = await _getUserInfo(tokenData['access_token']);

      // 6. Criar objeto Usuario
      final usuario = Usuario(
        cpf: userInfo['cpf'] ?? '',
        nome: userInfo['name'] ?? '',
        email: userInfo['email'],
        accessToken: tokenData['access_token'],
        refreshToken: tokenData['refresh_token'],
        tokenExpiry: DateTime.now().add(
          Duration(seconds: tokenData['expires_in'] ?? 3600),
        ),
      );

      // 7. Salvar dados
      await _saveUserData(usuario);
      _usuarioAtual = usuario;

      return usuario;
    } catch (e) {
      throw Exception('Erro ao fazer login: $e');
    }
  }

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
    // Gerar string aleatória para segurança
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return random;
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
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao obter dados: ${response.body}');
    }
  }
}
```

## 🧪 Testar Integração

### Ambiente de Homologação

O Gov.br oferece ambiente de testes:

```dart
// Para testes
static const String _authorizationEndpoint =
    'https://sso.staging.acesso.gov.br/authorize';
static const String _tokenEndpoint =
    'https://sso.staging.acesso.gov.br/token';
static const String _userInfoEndpoint =
    'https://sso.staging.acesso.gov.br/userinfo';
```

### Usuário de Teste

Você pode criar usuários de teste no portal do Gov.br para homologação.

## 🔍 Debug e Troubleshooting

### Erro: "redirect_uri_mismatch"

- Verifique se o redirect_uri no código é EXATAMENTE igual ao cadastrado no Gov.br
- Não pode ter / no final
- Case-sensitive

### Erro: "invalid_client"

- Verifique Client ID e Client Secret
- Confirme se está usando o endpoint correto (homologação vs produção)

### Erro: Deep link não funciona

- **Android**: Teste com `adb shell am start -a android.intent.action.VIEW -d "comprovapp://callback?code=123"`
- **iOS**: Configure Associated Domains se necessário

### Ver logs de requisição

```dart
import 'package:http/http.dart' as http;

final response = await http.post(url, body: body);
print('Status: ${response.statusCode}');
print('Body: ${response.body}');
```

## 🚀 Deploy para Produção

### Checklist

- [ ] Registrar app no Gov.br (produção)
- [ ] Obter credenciais de produção
- [ ] Configurar variáveis de ambiente
- [ ] Usar endpoints de produção (não staging)
- [ ] Testar fluxo completo
- [ ] Configurar ProGuard (Android) para não ofuscar classes OAuth2
- [ ] Adicionar tratamento de erros robusto
- [ ] Implementar analytics/logging
- [ ] Documentar para usuários finais

### Configuração ProGuard (Android)

Adicione em `android/app/proguard-rules.pro`:

```proguard
-keep class com.your.package.** { *; }
-keep class io.flutter.** { *; }
-dontwarn com.google.**
```

### Build de Produção

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## 📚 Recursos Úteis

- [Documentação Gov.br](https://manual-roteiro-integracao-login-unico.servicos.gov.br/)
- [FAQ Gov.br](https://faq-login-unico.servicos.gov.br/)
- [Suporte Gov.br](https://www.gov.br/governodigital/pt-br/identidade/acesso-gov-br)
- [Flutter Web Auth](https://pub.dev/packages/flutter_web_auth)
- [OAuth2 Package](https://pub.dev/packages/oauth2)

## 💡 Dicas Importantes

1. **Sempre use HTTPS** em produção
2. **Valide o state** para prevenir CSRF
3. **Nunca commite** credenciais no Git
4. **Use refresh token** para renovar automaticamente
5. **Implemente timeout** nas requisições
6. **Adicione retry logic** para falhas de rede
7. **Criptografe dados sensíveis** no storage
8. **Teste em dispositivos reais** antes de publicar

---

**Dúvidas?** Consulte a [documentação oficial do Gov.br](https://manual-roteiro-integracao-login-unico.servicos.gov.br/)
