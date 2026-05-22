import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _profile;
  Map<String, int>      _monthStats  = {};
  List<Map<String, dynamic>> _topTracks = [];
  int _totalSeconds        = 0;
  int _goalHours           = 20;
  int _totalSurahsHeard    = 0;
  int _favouritesCount     = 0;
  bool _loading            = true;

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final profile      = await AuthService.getProfile();
    final total        = await FirestoreService.getTotalSeconds();
    final month        = await FirestoreService.getMonthStats();
    final top          = await FirestoreService.getTopTracks();
    final surahsHeard  = await FirestoreService.getTotalSurahsListened();
    final favCount     = await FirestoreService.getFavouritesCount();
    if (!mounted) return;
    setState(() {
      _profile           = profile;
      _totalSeconds      = total;
      _monthStats        = month;
      _topTracks         = top;
      _goalHours         = profile?['monthlyGoalHours'] as int? ?? 20;
      _totalSurahsHeard  = surahsHeard;
      _favouritesCount   = favCount;
      _loading           = false;
    });
    _fadeCtrl.forward(from: 0);
  }

  // ── Computed helpers ───────────────────────────────────────────────────────
  String _fmt(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    return '${h}h ${m}m';
  }

  int get _thisMonthSeconds =>
      _monthStats.values.fold(0, (a, b) => a + b);

  String get _mostActiveDay {
    if (_monthStats.isEmpty) return '—';
    final entry =
        _monthStats.entries.reduce((a, b) => a.value > b.value ? a : b);
    final date = DateTime.tryParse(entry.key);
    if (date == null) return '—';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  int get _avgDailySeconds {
    if (_monthStats.isEmpty) return 0;
    return _thisMonthSeconds ~/ _monthStats.length;
  }

  // ── Monthly-goal dialog ────────────────────────────────────────────────────
  Future<void> _editGoal() async {
    int temp = _goalHours;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Monthly Goal',
              style: TextStyle(
                  color: AppTheme.primaryText, fontWeight: FontWeight.w700)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Set your monthly listening goal in hours',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _goalBtn(Icons.remove, () {
                if (temp > 1) setD(() => temp--);
              }),
              const SizedBox(width: 20),
              Column(children: [
                Text('$temp',
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.accentGold)),
                Text('hours / month',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
              ]),
              const SizedBox(width: 20),
              _goalBtn(Icons.add, () {
                if (temp < 200) setD(() => temp++);
              }),
            ]),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: AppTheme.textSecondary))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(0, 40),
              ),
              onPressed: () async {
                await FirestoreService.saveMonthlyGoal(temp);
                if (mounted) setState(() => _goalHours = temp);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppTheme.accentGold.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: AppTheme.accentGold),
        ),
      );

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accentGold));
    }

    final fName   = _profile?['firstName'] ?? 'User';
    final lName   = _profile?['lastName']  ?? '';
    final progress =
        (_thisMonthSeconds / (_goalHours * 3600)).clamp(0.0, 1.0);

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.accentGold,
          backgroundColor: AppTheme.surfaceCard,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const SizedBox(height: 16),

              // ── Hero Card ────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: AppTheme.accentGold.withValues(alpha: 0.2)),
                  image: DecorationImage(
                      image: const NetworkImage(AppTheme.heroImage),
                      opacity: 0.05,
                      fit: BoxFit.cover),
                  boxShadow: AppTheme.goldGlow(opacity: 0.15, blur: 20),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Container(
                    width: 36,
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const Text('WELCOME BACK,',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white60,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  Text('$fName $lName',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  Row(children: [
                    _miniStat('Total',      _fmt(_totalSeconds)),
                    const SizedBox(width: 8),
                    _miniStat('This Month', _fmt(_thisMonthSeconds)),
                  ]),
                ]),
              ),

              const SizedBox(height: 24),

              // ── Monthly Goal ─────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionTitle('Monthly Goal'),
                  GestureDetector(
                    onTap: _editGoal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                AppTheme.accentGold.withValues(alpha: 0.3)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.edit_outlined,
                            color: AppTheme.accentGold, size: 12),
                        SizedBox(width: 4),
                        Text('Edit',
                            style: TextStyle(
                                color: AppTheme.accentGold,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ],
              ),

              _statCard(child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text:
                            '${(_thisMonthSeconds / 3600).toStringAsFixed(1)}h',
                        style: const TextStyle(
                            color: AppTheme.accentGold,
                            fontWeight: FontWeight.w800,
                            fontSize: 18),
                      ),
                      TextSpan(
                        text: ' / ${_goalHours}h',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ]),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${(progress * 100).toInt()}%',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.accentGold,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 14),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, val, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: val,
                      minHeight: 8,
                      color: AppTheme.accentGold,
                      backgroundColor: AppTheme.background,
                    ),
                  ),
                ),
              ])),

              const SizedBox(height: 24),

              // ── Highlights Grid ──────────────────────────────────────────
              _sectionTitle('Highlights'),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.65,
                children: [
                  _highlightCard(
                      Icons.library_music_outlined, 'Surahs Heard',
                      '$_totalSurahsHeard'),
                  _highlightCard(
                      Icons.favorite_outline, 'Saved',
                      '$_favouritesCount'),
                  _highlightCard(
                      Icons.trending_up_rounded, 'Most Active Day',
                      _mostActiveDay),
                  _highlightCard(
                      Icons.timer_outlined, 'Avg / Day',
                      _fmt(_avgDailySeconds)),
                ],
              ),

              const SizedBox(height: 24),

              // ── Daily Activity Chart ─────────────────────────────────────
              _sectionTitle('Daily Activity — Last 7 Days'),
              _statCard(
                child: SizedBox(
                  height: 110,
                  child: BarChart(BarChartData(
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: Colors.white.withValues(alpha: 0.05),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, _) {
                            const days = [
                              'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
                            ];
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(days[val.toInt() % 7],
                                  style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 9)),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: _generateBars(),
                    barTouchData: BarTouchData(enabled: false),
                  )),
                ),
              ),

              const SizedBox(height: 28),

              // ── Most Listened ────────────────────────────────────────────
              _sectionTitle('Most Listened'),
              const SizedBox(height: 12),
              ..._topTracks.asMap().entries.map(
                    (e) => _TrackItem(
                        rank: e.key + 1, track: e.value, index: e.key),
                  ),

              const SizedBox(height: 24),

              // ── Logout ───────────────────────────────────────────────────
              GestureDetector(
                onTap: () async {
                  await AuthService.signOut();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                      (r) => false);
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Icon(Icons.logout, color: AppTheme.error, size: 18),
                    SizedBox(width: 10),
                    Text('Logout',
                        style: TextStyle(
                            color: AppTheme.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Chart bars ────────────────────────────────────────────────────────────
  List<BarChartGroupData> _generateBars() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final seconds = _monthStats[key] ?? 0;
      return BarChartGroupData(x: i, barRods: [
        BarChartRodData(
          toY: (seconds / 60) + 0.1,
          gradient: AppTheme.goldGradient,
          width: 14,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 10,
            color: Colors.white.withValues(alpha: 0.04),
          ),
        )
      ]);
    });
  }

  // ── Widgets ───────────────────────────────────────────────────────────────
  Widget _highlightCard(IconData icon, String label, String value) =>
      Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        decoration: AppTheme.cardDecoration(),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.accentGold, size: 16),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryText)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3)),
        ]),
      );

  Widget _miniStat(String label, String value) => Expanded(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.08))),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
            const SizedBox(height: 3),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryText)),
          ]),
        ),
      );

  Widget _statCard({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(top: 10),
        decoration: AppTheme.cardDecoration(),
        child: child,
      );

  Widget _sectionTitle(String t) => Text(
        t.toUpperCase(),
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
            letterSpacing: 1.5),
      );
}

// ─── Track Item ───────────────────────────────────────────────────────────────
class _TrackItem extends StatefulWidget {
  final int rank;
  final Map track;
  final int index;
  const _TrackItem({required this.rank, required this.track, required this.index});

  @override
  State<_TrackItem> createState() => _TrackItemState();
}

class _TrackItemState extends State<_TrackItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset>  _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.cardDecoration(),
          child: Row(children: [
            // Rank badge
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: widget.rank <= 3 ? AppTheme.goldGradient : null,
                color: widget.rank > 3 ? AppTheme.surface : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('${widget.rank}',
                    style: TextStyle(
                      color: widget.rank <= 3
                          ? Colors.black
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    )),
              ),
            ),
            const SizedBox(width: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(AppTheme.playerArt,
                  width: 42, height: 42, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(widget.track['surahEnglishName'] ?? 'Surah',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppTheme.primaryText)),
                const SizedBox(height: 3),
                Text('${widget.track['count']} plays',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ]),
            ),
            const Icon(Icons.bar_chart_rounded,
                color: AppTheme.accentGold, size: 18),
          ]),
        ),
      ),
    );
  }
}