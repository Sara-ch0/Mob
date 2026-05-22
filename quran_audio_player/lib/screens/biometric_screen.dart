import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../services/biometric_service.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class BiometricScreen extends StatefulWidget {
  const BiometricScreen({super.key});
  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _pulse;
  late final Animation<double> _fade;

  final _audio = AudioPlayer();
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.1).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    setState(() => _loading = true);
    final ok = await BiometricService.authenticate(
        reason: 'Enter your Digital Sanctuary');
    if (ok && mounted) {
      try {
        await _audio.setAsset('assets/sounds/success.mp3');
        _audio.play();
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 500));
      final user = AuthService.currentUser;
      if (mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    user != null ? const MainShell() : const LoginScreen()));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SizedBox.expand(
        child: FadeTransition(
          opacity: _fade,
          child: Stack(children: [
            // Background radial glow
            Positioned(
              top: size.height * 0.25,
              left: size.width / 2 - 150,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accentGold.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main content centered
            Column(
              children: [
                // Top section — app name
                SizedBox(
                  height: size.height * 0.28,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.nights_stay,
                          size: 40, color: AppTheme.accentGold),
                      SizedBox(height: 12),
                      Text('TARTIL',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryText,
                            letterSpacing: 6,
                          )),
                      SizedBox(height: 6),
                    ],
                  ),
                ),

                // Middle section — fingerprint
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: _loading ? null : _authenticate,
                      child: ScaleTransition(
                        scale: _pulse,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppTheme.accentGold, width: 2),
                            color: AppTheme.accentGold.withValues(alpha: 0.1),
                            boxShadow:
                                AppTheme.goldGlow(opacity: 0.3, blur: 30),
                          ),
                          child: _loading
                              ? const Padding(
                                  padding: EdgeInsets.all(36),
                                  child: CircularProgressIndicator(
                                      color: AppTheme.accentGold,
                                      strokeWidth: 2.5),
                                )
                              : const Icon(Icons.fingerprint,
                                  size: 70, color: AppTheme.accentGold),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom section — hint
                SizedBox(
                  height: size.height * 0.22,
                  child: Column(
                    children: [
                      const Text('TOUCH SENSOR TO CONTINUE',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 2.5,
                            color: Colors.white38,
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(height: 32),
                      Text('بسم الله الرحمن الرحيم',
                          style: TextStyle(
                            color: AppTheme.accentGold.withValues(alpha: 0.5),
                            fontSize: 14,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}