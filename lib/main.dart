import 'package:comprovapp/pages/auth/login_page.dart';
import 'package:comprovapp/pages/auth/welcome_page.dart';
import 'package:comprovapp/pages/dashboard/dashboard_page.dart';
import 'package:comprovapp/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'config/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ComprovApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _primeiroAcesso = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final authenticated = await _authService.isAuthenticated();
    if (!authenticated) {
      // Verifica se é a primeira vez (nunca usou "lembrar-me")
      final prefs = await SharedPreferences.getInstance();
      final jaUsouApp = prefs.getBool('app_used') ?? false;
      await prefs.setBool('app_used', true);
      setState(() {
        _isAuthenticated = authenticated;
        _isLoading = false;
        _primeiroAcesso = !jaUsouApp;
      });
    } else {
      setState(() {
        _isAuthenticated = true;
        _isLoading = false;
        _primeiroAcesso = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isAuthenticated
        ? const DashboardPage()
        : (_primeiroAcesso ? const WelcomePage() : const LoginPage());
  }
}
