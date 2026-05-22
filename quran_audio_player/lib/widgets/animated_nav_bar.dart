import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class AnimatedNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const AnimatedNavItem(
      {required this.icon, required this.activeIcon, required this.label});
}

class AnimatedBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final List<AnimatedNavItem> items;
  final ValueChanged<int> onTap;

  const AnimatedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  State<AnimatedBottomNavBar> createState() => _AnimatedBottomNavBarState();
}

class _AnimatedBottomNavBarState extends State<AnimatedBottomNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _pill;
  int _from = 0;

  @override
  void initState() {
    super.initState();
    _from = widget.currentIndex;
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _pill = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(AnimatedBottomNavBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _from = old.currentIndex;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.items.length;
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppTheme.navyHeader,
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4), blurRadius: 16),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemW = constraints.maxWidth / count;
          const pillW = 44.0;
          return Stack(children: [
            // ── sliding gold pill indicator ──────────────────────────────
            AnimatedBuilder(
              animation: _pill,
              builder: (_, __) {
                final fromX = _from * itemW + (itemW - pillW) / 2;
                final toX =
                    widget.currentIndex * itemW + (itemW - pillW) / 2;
                final x = fromX + (toX - fromX) * _pill.value;
                return Positioned(
                  left: x,
                  top: 0,
                  child: Container(
                    width: pillW,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(3)),
                      boxShadow: AppTheme.goldGlow(opacity: 0.6, blur: 8),
                    ),
                  ),
                );
              },
            ),
            // ── nav items ────────────────────────────────────────────────
            Row(
              children: List.generate(count, (i) {
                final active = widget.currentIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            key: ValueKey(active),
                            active
                                ? widget.items[i].activeIcon
                                : widget.items[i].icon,
                            color: active
                                ? AppTheme.accentGold
                                : Colors.white30,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: active
                                ? AppTheme.accentGold
                                : Colors.white30,
                          ),
                          child: Text(widget.items[i].label),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ]);
        },
      ),
    );
  }
}
