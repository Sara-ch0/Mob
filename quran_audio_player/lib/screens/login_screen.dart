import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'main_shell.dart';
import '../widgets/auth_field.dart';
import '../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true, _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final err =
        await AuthService.login(_email.text.trim(), _pass.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const MainShell()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(children: [
        // Decorative top-right radial glow
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppTheme.accentGold.withValues(alpha: 0.07),
                Colors.transparent,
              ]),
            ),
          ),
        ),

        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _form,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),

                    // Logo row
                    Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppTheme.goldGradient,
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: AppTheme.goldGlow(
                              opacity: 0.35, blur: 12),
                        ),
                        child: const Icon(
                            Icons.spatial_audio_off_rounded,
                            color: Colors.black,
                            size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text('Tartil',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryText)),
                    ]),

                    const SizedBox(height: 52),

                    const Text('Welcome back',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryText)),
                    const SizedBox(height: 6),
                    const Text('Sign in to continue',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 15)),

                    const SizedBox(height: 36),

                    // Form card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.glassDecoration(radius: 22),
                      child: Column(children: [
                        AuthField(
                            ctrl: _email,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) =>
                                (v?.contains('@') ?? false)
                                    ? null
                                    : 'Enter a valid email'),
                        const SizedBox(height: 14),
                        AuthField(
                            ctrl: _pass,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            obscure: _obscure,
                            onToggle: () =>
                                setState(() => _obscure = !_obscure),
                            validator: (v) =>
                                v!.isEmpty ? 'Enter password' : null),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen())),
                            child: const Text('Forgot password?',
                                style: TextStyle(
                                    color: AppTheme.accentGold,
                                    fontSize: 13)),
                          ),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 16),

                    // Error box
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _error != null
                          ? _ErrorBox(key: const ValueKey('err'), _error!)
                          : const SizedBox(key: ValueKey('no-err')),
                    ),

                    const SizedBox(height: 20),
                    PrimaryButton(
                        label: 'Sign In',
                        loading: _loading,
                        onPressed: _login),
                    const SizedBox(height: 28),

                    // Register link
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text("Don't have an account? ",
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 14)),
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen())),
                        child: const Text('Create one',
                            style: TextStyle(
                                color: AppTheme.accentGold,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ),
                    ]),
                    const SizedBox(height: 40),
                  ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String msg;
  const _ErrorBox(this.msg, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppTheme.error.withValues(alpha: 0.35)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg,
                  style: const TextStyle(
                      color: AppTheme.error, fontSize: 13))),
        ]),
      );
}
