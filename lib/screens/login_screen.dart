import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  final resetEmailController = TextEditingController();
  final resetCodeController = TextEditingController();
  final newPasswordController = TextEditingController();
  final verifyCodeController = TextEditingController();

  bool isLogin = true;
  bool loading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _showNewPassword = false;
  bool _forgotPassword = false;
  bool _resetCodeSent = false;
  bool _resetCodeVerified = false;
  bool _verifyingEmail = false;
  String _registeredEmail = '';
  String error = '';
  String success = '';

  Future<void> _submit() async {
    setState(() { loading = true; error = ''; success = ''; });

    if (!isLogin) {
      if (nameController.text.isEmpty) {
        setState(() { error = 'Full name is required'; loading = false; });
        return;
      }
      if (passwordController.text != confirmPasswordController.text) {
        setState(() { error = 'Passwords do not match'; loading = false; });
        return;
      }
      if (passwordController.text.length < 6) {
        setState(() { error = 'Password must be at least 6 characters'; loading = false; });
        return;
      }
    }

    try {
      if (isLogin) {
        final result = await ApiService.login(emailController.text, passwordController.text);
        if (result['success'] == true) {
          await ApiService.saveToken(result['token']);
          if (mounted) {
            Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()));
          }
        } else if (result['requiresVerification'] == true) {
          setState(() {
            _verifyingEmail = true;
            _registeredEmail = result['email'] ?? emailController.text;
            success = 'A new verification code has been sent to ${result['email'] ?? emailController.text}';
            error = '';
          });
        } else {
          setState(() { error = result['error'] ?? 'Something went wrong'; });
        }
      } else {
        final result = await ApiService.register(
          emailController.text,
          passwordController.text,
          name: nameController.text,
        );
        if (result['success'] == true) {
          setState(() {
            _verifyingEmail = true;
            _registeredEmail = emailController.text;
            success = 'Verification code sent to ${emailController.text}';
          });
        } else {
          setState(() { error = result['error'] ?? 'Something went wrong'; });
        }
      }
    } catch (e) {
      setState(() { error = 'Connection failed. Check internet.'; });
    }
    setState(() { loading = false; });
  }

  Future<void> _verifyEmail() async {
    if (verifyCodeController.text.length != 6) {
      setState(() => error = 'Enter the 6-digit code');
      return;
    }
    setState(() { loading = true; error = ''; success = ''; });
    try {
      final result = await ApiService.verifyEmail(_registeredEmail, verifyCodeController.text);
      if (result['success'] == true) {
        setState(() {
          _verifyingEmail = false;
          isLogin = true;
          success = 'Email verified! You can now login.';
          verifyCodeController.clear();
        });
      } else {
        setState(() => error = result['error'] ?? 'Invalid code');
      }
    } catch (e) {
      setState(() => error = 'Connection failed.');
    }
    setState(() => loading = false);
  }

  Future<void> _resendVerification() async {
    setState(() { loading = true; error = ''; success = ''; });
    try {
      final result = await ApiService.resendVerification(_registeredEmail);
      if (result['success'] == true) {
        setState(() { success = 'Code resent to $_registeredEmail'; });
      } else {
        setState(() { error = result['error'] ?? 'Failed to resend'; });
      }
    } catch (e) {
      setState(() { error = 'Connection failed.'; });
    }
    setState(() => loading = false);
  }

  Future<void> _sendResetCode() async {
    if (resetEmailController.text.isEmpty) {
      setState(() => error = 'Please enter your email');
      return;
    }
    setState(() { loading = true; error = ''; success = ''; });
    try {
      final result = await ApiService.sendResetCode(resetEmailController.text);
      if (result['success'] == true) {
        setState(() { _resetCodeSent = true; success = 'Reset code sent to your email!'; });
      } else {
        setState(() => error = result['error'] ?? 'Failed to send reset code');
      }
    } catch (e) {
      setState(() => error = 'Connection failed. Check internet.');
    }
    setState(() => loading = false);
  }

  Future<void> _verifyResetCode() async {
    if (resetCodeController.text.length != 6) {
      setState(() => error = 'Enter the 6-digit code');
      return;
    }
    setState(() { loading = true; error = ''; success = ''; });
    try {
      final result = await ApiService.verifyResetCode(
        resetEmailController.text, resetCodeController.text);
      if (result['success'] == true) {
        setState(() { _resetCodeVerified = true; success = 'Code verified! Set your new password.'; });
      } else {
        setState(() => error = result['error'] ?? 'Invalid code');
      }
    } catch (e) {
      setState(() => error = 'Connection failed.');
    }
    setState(() => loading = false);
  }

  Future<void> _resetPassword() async {
    if (newPasswordController.text.length < 6) {
      setState(() => error = 'Password must be at least 6 characters');
      return;
    }
    setState(() { loading = true; error = ''; success = ''; });
    try {
      final result = await ApiService.resetPassword(
        resetEmailController.text, resetCodeController.text, newPasswordController.text);
      if (result['success'] == true) {
        setState(() {
          _forgotPassword = false;
          _resetCodeSent = false;
          _resetCodeVerified = false;
          isLogin = true;
          success = 'Password reset! Please login.';
        });
      } else {
        setState(() => error = result['error'] ?? 'Failed to reset password');
      }
    } catch (e) {
      setState(() => error = 'Connection failed.');
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Xx Logo
              Text('Xx',
                style: GoogleFonts.orbitron(
                  fontSize: 64, fontWeight: FontWeight.w900,
                  color: const Color(0xFF00D4FF),
                  shadows: [
                    const Shadow(color: Color(0xFF00D4FF), blurRadius: 30),
                    Shadow(color: const Color(0xFF00D4FF).withValues(alpha: 0.5), blurRadius: 60),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Xx Smart Systems',
                style: GoogleFonts.orbitron(
                    fontSize: 14, fontWeight: FontWeight.bold,
                    color: Colors.white, letterSpacing: 1)),
              const SizedBox(height: 32),

              // EMAIL VERIFICATION FLOW
              if (_verifyingEmail) ...[
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.mark_email_unread_outlined,
                      color: Color(0xFF00D4FF), size: 30),
                ),
                const SizedBox(height: 20),
                Text('VERIFY YOUR EMAIL',
                    style: GoogleFonts.orbitron(
                        color: Colors.white, fontSize: 16, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(
                  'We sent a 6-digit code to\n$_registeredEmail',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.rajdhani(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 28),
                _buildTextField(
                  controller: verifyCodeController,
                  hint: '6-digit verification code',
                  icon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                const SizedBox(height: 24),
                _buildButton('VERIFY EMAIL', _verifyEmail, loading),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: loading ? null : _resendVerification,
                  child: Text('Resend code',
                      style: GoogleFonts.rajdhani(
                          color: const Color(0xFF00D4FF), fontSize: 14)),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => setState(() {
                    _verifyingEmail = false;
                    isLogin = true;
                    error = '';
                    success = '';
                  }),
                  child: Text('Back to Login',
                      style: GoogleFonts.rajdhani(
                          color: const Color(0xFF00D4FF), fontSize: 14)),
                ),
              ]

              // FORGOT PASSWORD FLOW
              else if (_forgotPassword) ...[
                Text('Reset Password',
                    style: GoogleFonts.orbitron(
                        fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text('We will send a code to your email',
                    style: GoogleFonts.rajdhani(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 32),
                if (!_resetCodeSent) ...[
                  _buildTextField(controller: resetEmailController,
                      hint: 'Email', icon: Icons.email_outlined),
                  const SizedBox(height: 24),
                  _buildButton('SEND RESET CODE', _sendResetCode, loading),
                ] else if (!_resetCodeVerified) ...[
                  Text('Enter the 6-digit code sent to\n${resetEmailController.text}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 20),
                  _buildTextField(controller: resetCodeController,
                      hint: '6-digit code', icon: Icons.pin_outlined,
                      keyboardType: TextInputType.number, maxLength: 6),
                  const SizedBox(height: 24),
                  _buildButton('VERIFY CODE', _verifyResetCode, loading),
                ] else ...[
                  _buildTextField(
                    controller: newPasswordController, hint: 'New Password',
                    icon: Icons.lock_outline, obscure: !_showNewPassword,
                    suffix: IconButton(
                      icon: Icon(_showNewPassword
                          ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey, size: 20),
                      onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildButton('RESET PASSWORD', _resetPassword, loading),
                ],
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() {
                    _forgotPassword = false;
                    _resetCodeSent = false;
                    _resetCodeVerified = false;
                    error = ''; success = '';
                  }),
                  child: Text('Back to Login',
                      style: GoogleFonts.rajdhani(
                          color: const Color(0xFF00D4FF), fontSize: 14)),
                ),
              ]

              // LOGIN / REGISTER FLOW
              else ...[
                Text(isLogin ? 'Welcome Back' : 'Create Account',
                    style: GoogleFonts.orbitron(
                        fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text(isLogin ? 'Login to your platform' : 'Join Xx Smart Systems',
                    style: GoogleFonts.rajdhani(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 32),

                if (!isLogin) ...[
                  _buildTextField(controller: nameController,
                      hint: 'Full Name', icon: Icons.person_outline),
                  const SizedBox(height: 16),
                ],
                _buildTextField(controller: emailController,
                    hint: 'Email', icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: passwordController, hint: 'Password',
                  icon: Icons.lock_outline, obscure: !_showPassword,
                  suffix: IconButton(
                    icon: Icon(_showPassword
                        ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey, size: 20),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
                if (!isLogin) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: confirmPasswordController, hint: 'Confirm Password',
                    icon: Icons.lock_outline, obscure: !_showConfirmPassword,
                    suffix: IconButton(
                      icon: Icon(_showConfirmPassword
                          ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey, size: 20),
                      onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                    ),
                  ),
                ],
                if (isLogin) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() {
                        _forgotPassword = true; error = ''; success = '';
                      }),
                      child: Text('Forgot Password?',
                          style: GoogleFonts.rajdhani(
                              color: const Color(0xFF00D4FF), fontSize: 13)),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _buildButton(isLogin ? 'LOGIN' : 'REGISTER', _submit, loading),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() {
                    isLogin = !isLogin; error = ''; success = '';
                  }),
                  child: Text(
                    isLogin ? "Don't have an account? Register"
                        : "Already have an account? Login",
                    style: GoogleFonts.rajdhani(
                        color: const Color(0xFF00D4FF), fontSize: 14)),
                ),
              ],

              // Error
              if (error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFF5252).withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Color(0xFFFF5252), size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(error,
                        style: GoogleFonts.rajdhani(
                            color: const Color(0xFFFF5252), fontSize: 13))),
                  ]),
                ),
              ],

              // Success
              if (success.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline,
                        color: Color(0xFF22C55E), size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(success,
                        style: GoogleFonts.rajdhani(
                            color: const Color(0xFF22C55E), fontSize: 13))),
                  ]),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.rajdhani(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF00D4FF), size: 20),
        suffixIcon: suffix,
        counterText: '',
        filled: true,
        fillColor: const Color(0xFF111827),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E2D45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E2D45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00D4FF)),
        ),
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onTap, bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFF00D4FF),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.4),
              blurRadius: 20, spreadRadius: 1)],
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.black)
              : Text(label,
                  style: GoogleFonts.orbitron(
                      color: Colors.black, fontSize: 13,
                      fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ),
      ),
    );
  }
}