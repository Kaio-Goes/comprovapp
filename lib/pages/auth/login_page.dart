import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _cpfController = TextEditingController();
  final _senhaController = TextEditingController();
  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );

  bool _isLoading = false;
  bool _obscureSenha = true;
  bool _lembrarMe = false;

  @override
  void dispose() {
    _cpfController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final cpf = _cpfFormatter.getUnmaskedText();
      final usuario = await _authService.login(
        cpf: cpf,
        senha: _senhaController.text,
        lembrarMe: _lembrarMe,
      );

      if (!mounted) return;

      if (usuario != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      } else {
        _showError('CPF ou senha inválidos. Verifique e tente novamente.');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Erro ao fazer login: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fundo azul Gov.br
          Container(color: AppColors.primary),

          // Padrão decorativo
          Positioned.fill(child: CustomPaint(painter: _DecorativePainter())),

          // Onda branca (conteúdo)
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipPath(
              clipper: _WaveClipper(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.78,
                color: Colors.white,
              ),
            ),
          ),

          // Conteúdo scrollável
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 80),

                  // Título
                  const Text(
                    'Entrar',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  // Linha decorativa
                  Container(
                    width: 40,
                    height: 3,
                    margin: const EdgeInsets.only(top: 6, bottom: 32),
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
                        // Campo CPF
                        const Text(
                          'CPF',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _cpfController,
                          hint: '000.000.000-00',
                          prefixIcon: Icons.badge_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [_cpfFormatter],
                          validator: (v) {
                            final digits = _cpfFormatter.getUnmaskedText();
                            if (digits.length != 11) {
                              return 'Informe um CPF válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Campo Senha
                        const Text(
                          'Senha',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _senhaController,
                          hint: 'digite sua senha',
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
                            onPressed: () =>
                                setState(() => _obscureSenha = !_obscureSenha),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Informe sua senha';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Lembrar-me
                        Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: _lembrarMe,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (v) =>
                                    setState(() => _lembrarMe = v ?? false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Lembrar-me',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF2D2D2D),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Botão Entrar
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
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
                                    'Entrar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Cadastro
                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: 'Primeiro acesso? ',
                              style: const TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 13,
                              ),
                              children: [
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () => _showCadastroInfo(),
                                    child: const Text(
                                      'Criar senha',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<dynamic>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters != null
          ? inputFormatters.cast()
          : null,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF2D2D2D)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: Colors.grey.shade400, size: 20),
        suffixIcon: suffixIcon,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
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

  void _showCadastroInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Criar Senha'),
        content: const Text(
          'Para criar sua senha, entre em contato com o administrador do sistema ou acesse as configurações do app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.08);
    path.quadraticBezierTo(
      size.width * 0.25, 0,
      size.width * 0.50, size.height * 0.06,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.12,
      size.width, size.height * 0.04,
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
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 5; i++) {
      final path = Path();
      final offset = i * 40.0;
      path.moveTo(size.width * 0.1 + offset, 0);
      path.cubicTo(
        size.width * 0.3 + offset, size.height * 0.15,
        size.width * 0.0 + offset, size.height * 0.30,
        size.width * 0.25 + offset, size.height * 0.50,
      );
      path.cubicTo(
        size.width * 0.45 + offset, size.height * 0.65,
        size.width * 0.10 + offset, size.height * 0.80,
        size.width * 0.30 + offset, size.height,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
