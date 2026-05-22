import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'biometric_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _glowCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();

    // Glow pulse — continuous
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _glowPulse = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // Logo: elastic scale + fade
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _logoCtrl,
            curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));

    // Text: fade + slide up
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _textFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn));
    _textSlide =
        Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
            CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    // Stagger: logo then text
    _logoCtrl.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 150),
          () => _textCtrl.forward());
    });

    Future.delayed(const Duration(milliseconds: 2400), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const BiometricScreen()));
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(children: [
        // Radial background glow
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 0.9,
                colors: [
                  AppTheme.emerald.withValues(alpha: 0.08),
                  AppTheme.bg,
                ],
              ),
            ),
          ),
        ),

        // Content
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Glow ring + logo
            AnimatedBuilder(
              animation: _glowPulse,
              builder: (_, child) => Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGold
                              .withValues(alpha: _glowPulse.value * 0.25),
                          blurRadius: 40,
                          spreadRadius: 10,
                        )
                      ],
                    ),
                  ),
                  // Inner ring
                  Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.accentGold
                            .withValues(alpha: _glowPulse.value * 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child!,
                ],
              ),
              child: ScaleTransition(
                scale: _logoScale,
                child: FadeTransition(
                  opacity: _logoFade,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow:
                          AppTheme.goldGlow(opacity: 0.45, blur: 24),
                    ),
                    child: const Icon(
                        Icons.spatial_audio_off_rounded,
                        color: Colors.black,
                        size: 44),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Staggered text
            FadeTransition(
              opacity: _textFade,
              child: SlideTransition(
                position: _textSlide,
                child: const Column(children: [
                  Text('TARTIL',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryText,
                        letterSpacing: 6,
                      )),
                  SizedBox(height: 8),
                  Text('Listen · Reflect · Connect',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        letterSpacing: 1.5,
                      )),
                ]),
              ),
            ),
          ]),
        ),

        // Bottom bismillah watermark
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: FadeTransition(
            opacity: _textFade,
            child: const Text(
              'بسم الله الرحمن الرحيم',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.accentGold,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ]),
    );
  }
}
