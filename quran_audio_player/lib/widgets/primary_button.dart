import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'scale_tap.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const PrimaryButton({
    super.key,
    required this.label,
    this.loading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: loading ? null : onPressed,
      scale: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: loading ? null : AppTheme.goldGradient,
          color: loading ? AppTheme.surface : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: loading ? [] : AppTheme.goldGlow(opacity: 0.35, blur: 14),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: loading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: AppTheme.accentGold, strokeWidth: 2.5),
                  )
                : Text(
                    key: const ValueKey('label'),
                    label,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
