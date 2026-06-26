import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLogin = true;
  bool loading = false;
  String error = '';

  Future<void> _submit() async {
    setState(() { loading = true; error = ''; });
    try {
      final result = isLogin
          ? await ApiService.login(emailController.text, passwordController.text)
          : await ApiService.register(emailController.text, passwordController.text);
      if (result['success'] == true) {
        if (isLogin) await ApiService.saveToken(result['token']);
        if (mounted) Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()));
      } else {
        setState(() { error = result['error'] ?? 'Something went wrong'; });
      }
    } catch (e) {
      setState(() { error = 'Connection failed. Check internet.'; });
    }
    setState(() { loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.3)),
                ),
                child: const Icon(Icons.developer_board, color: Color(0xFF00D4FF), size: 40),
              ),
              const SizedBox(height: 24),
              Text(isLogin ? 'Welcome Back' : 'Create Account',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text(isLogin ? 'Login to your platform' : 'Join XxSmart Systems',
                style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.email, color: Color(0xFF00D4FF)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E2D45)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00D4FF)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF00D4FF)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E2D45)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00D4FF)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF111827),
                ),
              ),
              if (error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(error, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4FF),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(isLogin ? 'Login' : 'Register',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() { isLogin = !isLogin; error = ''; }),
                child: Text(
                  isLogin ? "Don't have an account? Register" : "Already have an account? Login",
                  style: const TextStyle(color: Color(0xFF00D4FF)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}