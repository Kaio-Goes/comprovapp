import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );

  DateTime _dataNascimento = DateTime(2000, 1, 1);
  bool _isLoading = false;
  bool _obscureSenha = true;
  bool _obscureConfirmar = true;

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _handleCadastro() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.cadastrar(
        email: _emailController.text,
        senha: _senhaController.text,
        nomeCompleto: _nomeController.text.trim(),
        cpf: _cpfFormatter.getUnmaskedText(),
        dataNascimento: _dataNascimento,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardPage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(_mensagemErro(e.code));
    } catch (e) {
      if (!mounted) return;
      _showError('Erro ao criar conta. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mensagemErro(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      case 'invalid-email':
        return 'E-mail inválido.';
      default:
        return 'Erro ao criar conta. Tente novamente.';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  void _abrirDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            // Header
            Container(
              color: const Color(0xFFF7F7F7),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const Text(
                    'Data de Nascimento',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _dataNascimento,
                minimumDate: DateTime(1920),
                maximumDate: DateTime.now(),
                onDateTimeChanged: (date) {
                  setState(() => _dataNascimento = date);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: AppColors.primary),
          Positioned.fill(child: CustomPaint(painter: _DecorativePainter())),
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipPath(
              clipper: _WaveClipper(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.88,
                color: Colors.white,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Botão voltar
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 45),
                        const Text(
                          'Criar conta',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 3,
                          margin: const EdgeInsets.only(top: 6, bottom: 28),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nome completo
                              _buildLabel('Nome completo'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _nomeController,
                                hint: 'João da Silva',
                                prefixIcon: Icons.person_outline,
                                keyboardType: TextInputType.name,
                                textCapitalization: TextCapitalization.words,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Informe seu nome completo';
                                  }
                                  if (v.trim().split(' ').length < 2) {
                                    return 'Informe nome e sobrenome';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // CPF
                              _buildLabel('CPF'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _cpfController,
                                hint: '000.000.000-00',
                                prefixIcon: Icons.badge_outlined,
                                keyboardType: TextInputType.number,
                                inputFormatters: [_cpfFormatter],
                                validator: (v) {
                                  if (_cpfFormatter.getUnmaskedText().length != 11) {
                                    return 'Informe um CPF válido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Data de nascimento
                              _buildLabel('Data de nascimento'),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _abrirDatePicker,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 4),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                          color: Colors.grey.shade300),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.cake_outlined,
                                          color: Colors.grey.shade400,
                                          size: 20),
                                      const SizedBox(width: 12),
                                      Text(
                                        DateFormat('dd/MM/yyyy')
                                            .format(_dataNascimento),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(Icons.keyboard_arrow_down,
                                          color: Colors.grey.shade400),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // E-mail
                              _buildLabel('E-mail'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _emailController,
                                hint: 'seu@email.com',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Informe seu e-mail';
                                  }
                                  if (!v.contains('@') || !v.contains('.')) {
                                    return 'E-mail inválido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Senha
                              _buildLabel('Senha'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _senhaController,
                                hint: 'mínimo 6 caracteres',
                                prefixIcon: Icons.lock_outline,
                                obscureText: _obscureSenha,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureSenha
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscureSenha = !_obscureSenha),
                                ),
                                validator: (v) {
                                  if (v == null || v.length < 6) {
                                    return 'A senha deve ter pelo menos 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Confirmar senha
                              _buildLabel('Confirmar senha'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _confirmarSenhaController,
                                hint: 'repita a senha',
                                prefixIcon: Icons.lock_outline,
                                obscureText: _obscureConfirmar,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmar
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscureConfirmar = !_obscureConfirmar),
                                ),
                                validator: (v) {
                                  if (v != _senhaController.text) {
                                    return 'As senhas não coincidem';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 36),

                              // Botão Cadastrar
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleCadastro,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Criar conta',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Já tem conta
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Já tem conta? ',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.of(context).pop(),
                                      child: const Text(
                                        'Entrar',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<dynamic>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters:
          inputFormatters != null ? inputFormatters.cast() : null,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: Colors.grey.shade400, size: 20),
        suffixIcon: suffixIcon,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.05);
    path.quadraticBezierTo(
      size.width * 0.25, 0,
      size.width * 0.50, size.height * 0.04,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.08,
      size.width, size.height * 0.02,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _DecorativePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 5; i++) {
      final path = Path();
      final offset = i * 40.0;
      path.moveTo(size.width * 0.1 + offset, 0);
      path.cubicTo(
        size.width * 0.3 + offset, size.height * 0.1,
        size.width * 0.0 + offset, size.height * 0.2,
        size.width * 0.25 + offset, size.height * 0.35,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
