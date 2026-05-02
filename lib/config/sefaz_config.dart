import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Configuração do certificado A1 e dos endpoints da SEFAZ.
///
/// ## Como configurar o certificado A1
///
/// ### Opção 1 — Secure Storage (produção recomendada)
/// Use [salvarCertificado] para gravar o .pfx (em base64) e sua senha
/// no FlutterSecureStorage. Nunca versione o certificado real.
///
/// ### Opção 2 — Assets (teste/desenvolvimento)
/// Declare o arquivo em `assets/cert/certificado.pfx` no pubspec.yaml
/// e passe o caminho em [caminhoAsset].
class SefazConfig {
  /// Ambiente: `1` = Produção, `2` = Homologação
  final int tipoAmbiente;

  /// Código UF do estado (ex: 35 = SP, 43 = RS, 31 = MG)
  final int codigoUF;

  /// Senha do certificado A1 (.pfx)
  final String senhaCertificado;

  /// Caminho do certificado nos assets Flutter (opcional)
  final String? caminhoAsset;

  /// Quando `true` usa dados simulados (não chama a SEFAZ real)
  final bool modoSimulacao;

  const SefazConfig({
    this.tipoAmbiente = 2,
    this.codigoUF = 35,
    required this.senhaCertificado,
    this.caminhoAsset,
    this.modoSimulacao = true,
  });

  static const String _baseHomologacao =
      'https://hom.nfe.fazenda.gov.br/nfeservicos/services';
  static const String _baseProducao =
      'https://www.nfe.fazenda.gov.br/nfeservicos/services';

  String get _base =>
      tipoAmbiente == 1 ? _baseProducao : _baseHomologacao;

  /// Endpoint DistDFe — busca NF-e por CPF destinatário
  String get endpointDistDFe =>
      '$_base/NFeDistribuicaoDFe/NFeDistribuicaoDFe.asmx';

  /// Endpoint consulta NF-e por chave de acesso
  String get endpointConsultaProtocolo =>
      '$_base/NfeConsulta4/NfeConsulta4.asmx';

  /// Carrega os bytes do certificado A1 (.pfx).
  ///
  /// Prioridade: SecureStorage → asset.
  Future<Uint8List> carregarCertificado() async {
    const storage = FlutterSecureStorage();
    final base64Cert = await storage.read(key: 'cert_a1_bytes');
    if (base64Cert != null && base64Cert.isNotEmpty) {
      return base64.decode(base64Cert);
    }

    if (caminhoAsset != null) {
      final byteData = await rootBundle.load(caminhoAsset!);
      return byteData.buffer.asUint8List();
    }

    throw Exception(
      'Certificado A1 não configurado.\n'
      'Use SefazConfig.salvarCertificado() para gravar o .pfx\n'
      'no FlutterSecureStorage, ou defina caminhoAsset.',
    );
  }

  /// Grava o certificado A1 no FlutterSecureStorage (base64).
  static Future<void> salvarCertificado({
    required Uint8List certBytes,
    required String senha,
  }) async {
    const storage = FlutterSecureStorage();
    await storage.write(
        key: 'cert_a1_bytes', value: base64.encode(certBytes));
    await storage.write(key: 'cert_a1_senha', value: senha);
  }

  /// Cria instância lendo a senha do secure storage (produção).
  static Future<SefazConfig> fromSecureStorage({
    int tipoAmbiente = 1,
    int codigoUF = 35,
    bool modoSimulacao = false,
  }) async {
    const storage = FlutterSecureStorage();
    final senha = await storage.read(key: 'cert_a1_senha') ?? '';
    return SefazConfig(
      tipoAmbiente: tipoAmbiente,
      codigoUF: codigoUF,
      senhaCertificado: senha,
      modoSimulacao: modoSimulacao,
    );
  }
}
