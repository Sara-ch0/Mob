import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../widgets/auth_field.dart';
import '../widgets/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false, _sent = false;
  String? _error;

  @override void dispose() { _email.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (_email.text.trim().isEmpty || !_email.text.contains('@')) {
      setState(() => _error = 'Enter a valid email address.'); return;
    }
    setState(() { _loading = true; _error = null; });
    final err = await AuthService.resetPassword(_email.text.trim());
    if (!mounted) return;
    setState(() { _loading = false; if (err != null) {
      _error = err;
    } else {
      _sent = true;
    } });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password'), leading: const BackButton()),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: _sent ? _SuccessView() : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text('Forgot your password?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'Enter your registered email and we\'ll send you a reset link.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),
            AuthField(ctrl: _email, label: 'Email', icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            PrimaryButton(label: 'Send Reset Link', loading: _loading, onPressed: _send),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: AppTheme.accent.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.mark_email_read_outlined,
            color: AppTheme.accent, size: 40),
      ),
      const SizedBox(height: 20),
      const Text('Email sent!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Check your inbox and follow the link to reset your password.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, height: 1.5)),
      const SizedBox(height: 32),
      ElevatedButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Back to Login'),
      ),
    ]),
  );
}
