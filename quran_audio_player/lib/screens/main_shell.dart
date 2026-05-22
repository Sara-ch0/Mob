import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/animated_nav_bar.dart';
import '../widgets/user_avatar.dart';
import 'login_screen.dart';
import 'stats_screen.dart';
import 'player_screen.dart';
import 'favourites_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _statsKey = 0;
  int _settingsKey = 0;
  int _favouritesKey = 0;
  String? _firstName;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService.getProfile();
    if (mounted) {
      setState(() => _firstName = profile?['firstName'] as String?);
    }
  }

  String get _userKey => AuthService.currentUser?.uid ?? 'guest';

  List<Widget> get _screens => [
        StatsScreen(key: ValueKey('stats_$_statsKey')),
        PlayerScreen(key: ValueKey('player_$_userKey')),
        FavouritesScreen(key: ValueKey('fav_$_favouritesKey')),
        SettingsScreen(key: ValueKey('settings_$_settingsKey')),
      ];

  static const _navItems = [
    AnimatedNavItem(
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart,
        label: 'Insight'),
    AnimatedNavItem(
        icon: Icons.music_note_outlined,
        activeIcon: Icons.music_note,
        label: 'Player'),
    AnimatedNavItem(
        icon: Icons.favorite_outline,
        activeIcon: Icons.favorite,
        label: 'Saved'),
    AnimatedNavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        label: 'Settings'),
  ];

  static const _titles = ['Insight', 'Quran Player', 'Saved', 'Settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox(),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0, 0.3), end: Offset.zero)
                      .animate(anim),
                  child: child)),
          child: const Text(
            'TARTIL',
            key: ValueKey('title'),
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 3),
          ),
        ),
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Container(
              key: ValueKey(_index),
              margin: const EdgeInsets.only(right: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.3)),
              ),
              child: Text(
                _titles[_index],
                style: const TextStyle(
                    color: AppTheme.accentGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Consumer<ThemeProvider>(
            builder: (_, tp, __) => IconButton(
              icon: Icon(
                tp.isDark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                color: Colors.white70,
                size: 21,
              ),
              onPressed: tp.toggle,
              tooltip: tp.isDark ? 'Switch to light' : 'Switch to dark',
            ),
          ),
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            color: AppTheme.surfaceCard,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            onSelected: (value) async {
              if (value == 'logout') {
                await AuthService.signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()),
                    (r) => false);
              } else if (value == 'profile') {
                setState(() {
                  _index = 3;
                  _settingsKey++;
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'profile',
                  child: ListTile(
                      leading: Icon(Icons.person_outline,
                          color: AppTheme.textSecondary),
                      title: Text('My Account'))),
              const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                      leading: Icon(Icons.logout, color: AppTheme.error),
                      title: Text('Logout',
                          style: TextStyle(color: AppTheme.error)))),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: UserAvatar(firstName: _firstName, radius: 15),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: AnimatedBottomNavBar(
        currentIndex: _index,
        items: _navItems,
        onTap: (i) {
          setState(() {
            _index = i;
            if (i == 0) _statsKey++;
            if (i == 2) _favouritesKey++;
            if (i == 3) {
              _settingsKey++;
              _loadProfile();
            }
          });
        },
      ),
    );
  }
}
