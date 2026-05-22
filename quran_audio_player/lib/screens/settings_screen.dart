import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/download_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';
import '../widgets/user_avatar.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifEnabled  = false;
  TimeOfDay _notifTime = const TimeOfDay(hour: 8, minute: 0);
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _downloads = [];
  int _goalHours = 20;
  bool _loading  = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled   = await NotificationService.isEnabled();
    final time      = await NotificationService.getSavedTime();
    final profile   = await AuthService.getProfile();
    final downloads = await DownloadService.getDownloadedFiles();
    if (!mounted) return;
    setState(() {
      _notifEnabled = enabled;
      _notifTime    = time;
      _profile      = profile;
      _downloads    = downloads;
      _goalHours    = profile?['monthlyGoalHours'] as int? ?? 20;
      _loading      = false;
    });
  }

  int get _totalBytes =>
      _downloads.fold(0, (s, d) => s + (d['size'] as int));

  String _fmtBytes(int b) {
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accentGold));
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // ── Appearance ──────────────────────────────────────────────────
          _header('Appearance'),
          _card([_themeToggle(context)]),

          _gap(),

          // ── Notifications ───────────────────────────────────────────────
          _header('Notifications'),
          _card([
            _switchTile(
              icon: Icons.notifications_outlined,
              title: 'Daily Reminder',
              subtitle: 'Receive a daily Quran listening reminder',
              value: _notifEnabled,
              onChanged: (val) async {
                if (val) {
                  await NotificationService.scheduleDailyReminder(
                    hour: _notifTime.hour, minute: _notifTime.minute);
                } else {
                  await NotificationService.cancel();
                }
                setState(() => _notifEnabled = val);
              },
            ),
            if (_notifEnabled) ...[
              Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
              ListTile(
                leading: const Icon(Icons.access_time,
                    color: AppTheme.accentGold, size: 20),
                title: const Text('Reminder Time',
                    style: TextStyle(
                        color: AppTheme.primaryText, fontSize: 14)),
                trailing: Text(
                  _notifTime.format(context),
                  style: const TextStyle(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.w700),
                ),
                onTap: () async {
                        final t = await showTimePicker(
                            context: context, initialTime: _notifTime);
                        if (!mounted) return;
                        if (t != null) {
                          setState(() => _notifTime = t);
                          await NotificationService.scheduleDailyReminder(
                              hour: t.hour, minute: t.minute);
                        }
                      },
              ),
            ],
          ]),

          _gap(),

          // ── Monthly Goal ────────────────────────────────────────────────
          _header('Monthly Goal'),
          _card([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(children: [
                Row(children: [
                  const Icon(Icons.flag_outlined,
                      color: AppTheme.accentGold, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                      child: Text('Listening Goal',
                          style: TextStyle(
                              color: AppTheme.primaryText, fontSize: 14))),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$_goalHours h / month',
                        style: const TextStyle(
                            color: AppTheme.accentGold,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
                ]),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.accentGold,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: AppTheme.accentGold,
                    overlayColor:
                        AppTheme.accentGold.withValues(alpha: 0.12),
                  ),
                  child: Slider(
                    value: _goalHours.toDouble(),
                    min: 1,
                    max: 100,
                    divisions: 99,
                    label: '$_goalHours h',
                    onChanged: (v) => setState(() => _goalHours = v.round()),
                    onChangeEnd: (v) =>
                        FirestoreService.saveMonthlyGoal(v.round()),
                  ),
                ),
              ]),
            ),
          ]),

          _gap(),

          // ── Offline Storage ─────────────────────────────────────────────
          _header('Offline Storage'),
          _card([
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  const Icon(Icons.storage_outlined,
                      color: AppTheme.accentGold, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_downloads.length} surah(s) downloaded',
                      style: const TextStyle(
                          color: AppTheme.primaryText, fontSize: 14),
                    ),
                  ),
                  Text(_fmtBytes(_totalBytes),
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ]),
                if (_downloads.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppTheme.surfaceCard,
                            title: const Text('Delete All Downloads',
                                style: TextStyle(
                                    color: AppTheme.primaryText)),
                            content: const Text(
                                'Remove all offline surahs?',
                                style: TextStyle(
                                    color: AppTheme.textSecondary)),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: const Text('Cancel')),
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, true),
                                  child: const Text('Delete All',
                                      style: TextStyle(
                                          color: AppTheme.errorColor))),
                            ],
                          ),
                        );
                        if (!context.mounted) return;
                        if (ok == true) {
                          await DownloadService.deleteAll();
                          await _load();
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete All Downloads'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: BorderSide(
                            color: AppTheme.errorColor
                                .withValues(alpha: 0.4)),
                      ),
                    ),
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('No offline surahs downloaded yet',
                        style: TextStyle(
                            color: AppTheme.textMuted, fontSize: 12)),
                  ),
              ]),
            ),
          ]),

          _gap(),

          // ── Account ─────────────────────────────────────────────────────
          _header('Account'),
          _card([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(children: [
                UserAvatar(
                  firstName: _profile?['firstName'] as String?,
                  radius: 34,
                  showBorder: false,
                ),
                const SizedBox(height: 12),
                Text(
                  '${_profile?['firstName'] ?? ''} ${_profile?['lastName'] ?? ''}'
                      .trim(),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryText),
                ),
                const SizedBox(height: 4),
                Text(_profile?['email'] ?? '',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ]),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
            ListTile(
              leading:
                  const Icon(Icons.logout, color: AppTheme.errorColor, size: 20),
              title: const Text('Logout',
                  style: TextStyle(
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.w600)),
              onTap: () async {
                await AuthService.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (r) => false,
                  );
                }
              },
            ),
          ]),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  Widget _gap() => const SizedBox(height: 20);

  Widget _header(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
                letterSpacing: 1.5)),
      );

  Widget _card(List<Widget> children) => Container(
        decoration: AppTheme.cardDecoration(),
        child: Column(children: children),
      );

  Widget _themeToggle(BuildContext ctx) {
    final tp = ctx.watch<ThemeProvider>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Icon(tp.isDark ? Icons.dark_mode : Icons.light_mode,
            color: AppTheme.accentGold, size: 20),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Theme',
              style: TextStyle(color: AppTheme.primaryText, fontSize: 14)),
          Text(tp.isDark ? 'Dark mode' : 'Light mode',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11)),
        ]),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            _modeBtn(ctx, Icons.dark_mode,  ThemeMode.dark,  tp),
            _modeBtn(ctx, Icons.light_mode, ThemeMode.light, tp),
          ]),
        ),
      ]),
    );
  }

  Widget _modeBtn(BuildContext ctx, IconData icon, ThemeMode mode,
      ThemeProvider tp) {
    final active = tp.mode == mode;
    return GestureDetector(
      onTap: () => tp.setMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppTheme.accentGold : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon,
            color: active ? Colors.black : AppTheme.textSecondary, size: 18),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      SwitchListTile(
        secondary: Icon(icon, color: AppTheme.accentGold, size: 20),
        title: Text(title,
            style:
                const TextStyle(color: AppTheme.primaryText, fontSize: 14)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 11)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.accentGold,
      );
}
