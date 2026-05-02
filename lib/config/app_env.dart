/// Variáveis de ambiente injetadas via `--dart-define-from-file=.env`
///
/// Como usar:
///   flutter run --dart-define-from-file=.env
///   flutter build apk --dart-define-from-file=.env
///   flutter build ipa --dart-define-from-file=.env
///
/// O arquivo `.env` NÃO deve ser versionado no git.
/// Copie `.env.example` para `.env` e preencha os valores reais.
class AppEnv {
  AppEnv._();

  /// Senha do certificado A1 (.pfx).
  /// Vazia quando não configurada via --dart-define.
  static const String certSenha =
      String.fromEnvironment('CERT_SENHA', defaultValue: '');

  /// Retorna true se a senha do certificado foi fornecida em build-time.
  static bool get temCertSenha => certSenha.isNotEmpty;
}
