import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import 'main_shell.dart';
import '../widgets/auth_field.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  DateTime? _dob;
  bool _obscure = true, _obscureC = true, _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _pass, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme:
                const ColorScheme.dark(primary: AppTheme.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    if (_dob == null) {
      setState(() => _error = 'Please select your date of birth.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await AuthService.register(
      email: _email.text.trim(),
      password: _pass.text,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      birthDate: _dob!,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: const BackButton(),
      ),
      body: Stack(children: [
        // Decorative glow
        Positioned(
          top: -60,
          left: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppTheme.emerald.withValues(alpha: 0.08),
                Colors.transparent,
              ]),
            ),
          ),
        ),

        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Text('Join Tartil',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryText)),
              const SizedBox(height: 4),
              const Text('Fill in your details below',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 28),

              // ── Form card ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(22),
                decoration: AppTheme.glassDecoration(radius: 22),
                child: Column(children: [
                  AuthField(
                      ctrl: _firstName,
                      label: 'First Name *',
                      icon: Icons.person_outline,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Required' : null),
                  const SizedBox(height: 14),

                  AuthField(
                      ctrl: _lastName,
                      label: 'Last Name *',
                      icon: Icons.person_outline,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Required' : null),
                  const SizedBox(height: 14),

                  // Date picker — matches AuthField style
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.cake_outlined,
                            color: AppTheme.textSecondary, size: 20),
                        const SizedBox(width: 14),
                        Text(
                          _dob == null
                              ? 'Date of Birth *'
                              : DateFormat('dd MMM yyyy').format(_dob!),
                          style: TextStyle(
                            color: _dob == null
                                ? AppTheme.textSecondary
                                : AppTheme.primaryText,
                            fontSize: 14,
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 14),

                  AuthField(
                      ctrl: _email,
                      label: 'Email *',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          (v?.contains('@') ?? false)
                              ? null
                              : 'Enter a valid email'),
                  const SizedBox(height: 14),

                  AuthField(
                      ctrl: _pass,
                      label: 'Password *',
                      icon: Icons.lock_outline,
                      obscure: _obscure,
                      onToggle: () =>
                          setState(() => _obscure = !_obscure),
                      validator: (v) => v!.length < 6
                          ? 'At least 6 characters'
                          : null),
                  const SizedBox(height: 14),

                  AuthField(
                      ctrl: _confirm,
                      label: 'Confirm Password *',
                      icon: Icons.lock_outline,
                      obscure: _obscureC,
                      onToggle: () =>
                          setState(() => _obscureC = !_obscureC),
                      validator: (v) => v != _pass.text
                          ? 'Passwords do not match'
                          : null),
                ]),
              ),

              const SizedBox(height: 16),

              // Error
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _error != null
                    ? Container(
                        key: const ValueKey('err'),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.error
                                  .withValues(alpha: 0.35)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline,
                              color: AppTheme.error, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: AppTheme.error,
                                      fontSize: 13))),
                        ]),
                      )
                    : const SizedBox(key: ValueKey('no-err')),
              ),

              const SizedBox(height: 24),
              PrimaryButton(
                  label: 'Create Account',
                  loading: _loading,
                  onPressed: _register),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ]),
    );
  }
}
