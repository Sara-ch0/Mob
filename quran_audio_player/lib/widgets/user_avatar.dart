import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Profile circle showing the first letter of the user's first name.
class UserAvatar extends StatelessWidget {
  final String? firstName;
  final double radius;
  final bool showBorder;

  const UserAvatar({
    super.key,
    this.firstName,
    this.radius = 15,
    this.showBorder = true,
  });

  String get _letter {
    final name = firstName?.trim();
    if (name == null || name.isEmpty) return 'U';
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.accentGold,
      child: Text(
        _letter,
        style: TextStyle(
          color: Colors.black,
          fontSize: radius * 0.9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    if (!showBorder) return avatar;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: avatar,
    );
  }
}
