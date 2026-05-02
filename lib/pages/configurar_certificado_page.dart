import 'package:flutter/material.dart';
import '../config/sefaz_config.dart';
import '../config/app_colors.dart';

/// Tela para configurar a senha do certificado A1.
///
/// O arquivo `assets/cert/certificado.pfx` já está no app.
/// O usuário precisa informar a senha para que o SEFAZ possa usá-lo.
/// A senha é salva no FlutterSecureStorage (encriptado no dispositivo).
class ConfigurarCertificadoPage extends StatefulWidget {
  /// Se true, exibe como diálogo de primeiro uso (sem botão voltar obrigatório).
  final bool primeiroUso;

  const ConfigurarCertificadoPage({super.key, this.primeiroUso = false});

  @override
  State<ConfigurarCertificadoPage> createState() =>
      _ConfigurarCertificadoPageState();
}

class _ConfigurarCertificadoPageState
    extends State<ConfigurarCertificadoPage> {
  final _formKey = GlobalKey<FormState>();
  final _senhaCtrl = TextEditingController();
  bool _obscure = true;
  bool _salvando = false;
  bool _salvoComSucesso = false;
  String? _erro;

  @override
  void dispose() {
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      // Testa se consegue carregar o certificado com a senha informada
      final config = SefazConfig(
        senhaCertificado: _senhaCtrl.text.trim(),
        caminhoAsset: 'assets/cert/certificado.pfx',
        tipoAmbiente: 1,
        codigoUF: 53,
      );
      await config.carregarCertificado(); // valida leitura do asset

      // Salva a senha no SecureStorage
      await SefazConfig.salvarSenhaCertificado(_senhaCtrl.text.trim());

      if (mounted) {
        setState(() {
          _salvoComSucesso = true;
          _salvando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = 'Não foi possível carregar o certificado.\n'
              'Verifique se o arquivo certificado.pfx está correto.\n'
              'Detalhe: $e';
          _salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificado Digital A1'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: !widget.primeiroUso,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone e título
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.security_rounded,
                      size: 42, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Configurar Certificado A1',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'O arquivo certificado.pfx já está instalado no app.\n'
                  'Informe a senha para habilitar a consulta na SEFAZ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 32),

              // Info do arquivo
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file_outlined,
                        color: Colors.blue.shade700, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'certificado.pfx',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800),
                          ),
                          Text(
                            'assets/cert/certificado.pfx',
                            style: TextStyle(
                                fontSize: 11, color: Colors.blue.shade600),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle,
                        color: Colors.green.shade600, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Campo de senha
              TextFormField(
                controller: _senhaCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Senha do certificado',
                  hintText: 'Digite a senha do arquivo .pfx',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Informe a senha do certificado';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Aviso de segurança
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.amber.shade800, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'A senha é armazenada de forma segura no dispositivo '
                        '(Keychain/Keystore) e nunca enviada para servidores externos.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Erro
              if (_erro != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Text(
                    _erro!,
                    style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                  ),
                ),

              // Sucesso
              if (_salvoComSucesso)
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green.shade700, size: 22),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Certificado configurado com sucesso!\n'
                          'Você já pode sincronizar suas notas fiscais.',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Botão salvar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _salvando || _salvoComSucesso ? null : _salvar,
                  icon: _salvando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_salvoComSucesso
                      ? 'Salvo!'
                      : _salvando
                          ? 'Verificando...'
                          : 'Salvar senha'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              if (_salvoComSucesso) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Voltar'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
