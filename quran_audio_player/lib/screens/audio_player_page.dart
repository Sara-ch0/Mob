import 'dart:async';
import 'dart:math' as math;
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import '../models/surah_model.dart';
import '../services/ayah_service.dart';
import '../services/download_service.dart';
import '../services/firestore_service.dart';
import '../services/audio_handler.dart';
import '../utils/app_theme.dart';
import '../widgets/scale_tap.dart';

class AudioPlayerPage extends StatefulWidget {
  final Reciter reciter;
  final QuranAudioHandler handler;
  final bool isFavourite;
  final Future<void> Function(Reciter) onToggleFav;
  /// Full surah list for Prev/Next navigation. Optional.
  final List<Surah> surahs;
  final int initialSurahIndex;

  const AudioPlayerPage({
    super.key,
    required this.reciter,
    required this.handler,
    required this.isFavourite,
    required this.onToggleFav,
    this.surahs = const [],
    this.initialSurahIndex = 0,
  });

  @override
  State<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage>
    with TickerProviderStateMixin {
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying  = false;
  bool _isFav      = false;
  bool _isRepeat   = false;
  bool _seeking    = false;

  late Reciter _currentReciter;
  late int     _currentIndex;

  List<String> _ayahs = [];
  List<GlobalKey> _ayahKeys = [];
  List<int> _cumulativeChars = [];
  int _totalChars = 0;
  int _activeAyahIndex = 0;
  bool _loadingAyahs  = false;

  DownloadState _dlState =
      const DownloadState(status: DownloadStatus.idle);

  StreamSubscription? _posSub, _durSub, _stateSub;

  late final AnimationController _enterCtrl;
  late final Animation<double>   _enterFade;
  late final Animation<Offset>   _enterSlide;

  @override
  void initState() {
    super.initState();
    _isFav          = widget.isFavourite;
    _currentReciter = widget.reciter;
    _currentIndex   = widget.initialSurahIndex;

    // Entry animation
    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _enterFade  = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _enterSlide = Tween<Offset>(
            begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _enterCtrl, curve: Curves.easeOutCubic));
    _enterCtrl.forward();

    // Audio stream subscriptions
    _posSub = widget.handler.positionStream.listen((p) {
      if (!_seeking && mounted) {
        setState(() => _position = p);
        if (_ayahs.isNotEmpty && _duration.inMilliseconds > 0 && _totalChars > 0) {
          final progress = p.inMilliseconds / _duration.inMilliseconds;
          final targetChars = progress * _totalChars;
          
          int newIndex = 0;
          for (int i = 0; i < _cumulativeChars.length; i++) {
            if (targetChars <= _cumulativeChars[i]) {
              newIndex = i;
              break;
            }
          }
          newIndex = newIndex.clamp(0, _ayahs.length - 1);

          if (newIndex != _activeAyahIndex && newIndex < _ayahKeys.length) {
            _activeAyahIndex = newIndex;
            final key = _ayahKeys[newIndex];
            if (key.currentContext != null) {
              Scrollable.ensureVisible(
                key.currentContext!,
                duration: const Duration(milliseconds: 300),
                alignment: 0.5,
              );
            }
          }
        }
      }
    });
    _durSub = widget.handler.durationStream.listen((d) {
      if (mounted) setState(() => _duration = d ?? Duration.zero);
    });
    _stateSub = widget.handler.playerStateStream.listen((s) {
      if (!mounted) return;
      setState(() => _isPlaying = s.playing);
    });

    // Sync initial state
    _isPlaying = widget.handler.isPlaying;

    _checkDownload();
    _loadAyahs(_currentReciter.surahId);
    DownloadService.addListener(_currentReciter.audioUrl, _onDlChange);
  }

  void _onDlChange(DownloadState s) {
    if (mounted) setState(() => _dlState = s);
  }

  Future<void> _checkDownload() async {
    final done = await DownloadService.isDownloaded(_currentReciter.audioUrl);
    if (mounted) {
      setState(() => _dlState = DownloadState(
          status: done ? DownloadStatus.done : DownloadStatus.idle));
    }
  }

  Future<void> _loadAyahs(int surahId) async {
    if (mounted) setState(() { _loadingAyahs = true; _ayahs = []; _ayahKeys = []; _cumulativeChars = []; _totalChars = 0; });
    final list = await AyahService.fetchAyahs(surahId);
    
    int total = 0;
    List<int> cumulative = [];
    for (final a in list) {
      total += a.length;
      cumulative.add(total);
    }
    
    if (mounted) setState(() { 
      _ayahs = list; 
      _ayahKeys = List.generate(list.length, (_) => GlobalKey());
      _cumulativeChars = cumulative;
      _totalChars = total;
      _loadingAyahs = false; 
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _enterCtrl.dispose();
    DownloadService.removeListener(_currentReciter.audioUrl, _onDlChange);
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  bool get _hasPrev => widget.surahs.length > 1;
  bool get _hasNext => widget.surahs.length > 1;

  Future<void> _goNext() async {
    if (!_hasNext) return;
    await _playSurahAt((_currentIndex + 1) % widget.surahs.length);
  }

  Future<void> _goPrev() async {
    if (!_hasPrev) return;
    await _playSurahAt(
        (_currentIndex - 1 + widget.surahs.length) % widget.surahs.length);
  }

  Future<void> _playSurahAt(int index) async {
    final surah   = widget.surahs[index];
    final reciter = surah.reciters.first;

    DownloadService.removeListener(_currentReciter.audioUrl, _onDlChange);
    setState(() {
      _currentIndex   = index;
      _currentReciter = reciter;
      _position       = Duration.zero;
      _duration       = Duration.zero;
      _ayahs          = [];
      _ayahKeys       = [];
      _cumulativeChars = [];
      _totalChars      = 0;
      _activeAyahIndex = 0;
    });
    DownloadService.addListener(reciter.audioUrl, _onDlChange);
    _checkDownload();
    _loadAyahs(surah.id);

    final local = await DownloadService.getLocalPath(reciter.audioUrl);
    final url   = local != null ? 'file://$local' : reciter.audioUrl;
    await widget.handler.playUrl(url,
        MediaItem(id: url, title: reciter.surahEnglishName, artist: reciter.name));
    await FirestoreService.incrementPlayCount(reciter);
  }

  // ── Download ───────────────────────────────────────────────────────────────
  Future<void> _toggleDownload() async {
    if (_dlState.status == DownloadStatus.done) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: const Text('Remove Download',
              style: TextStyle(color: AppTheme.primaryText)),
          content: const Text('Delete this surah from offline storage?',
              style: TextStyle(color: AppTheme.textSecondary)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete',
                    style: TextStyle(color: AppTheme.errorColor))),
          ],
        ),
      );
      if (ok == true) await DownloadService.delete(_currentReciter.audioUrl);
    } else if (_dlState.status == DownloadStatus.idle ||
        _dlState.status == DownloadStatus.error) {
      DownloadService.download(_currentReciter);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress => _duration.inMilliseconds > 0
      ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
      : 0.0;

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: FadeTransition(
        opacity: _enterFade,
        child: SlideTransition(
          position: _enterSlide,
          child: Column(children: [
            _buildTopBar(),
            Expanded(child: _buildVersesList()),
            _buildTrackInfo(),
            _buildSlider(),
            _buildControls(),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() => SafeArea(
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                size: 32, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text('NOW PLAYING',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                    color: Colors.white60)),
          ),
          _downloadBtn(),
          ScaleTap(
            onTap: () async {
              await widget.onToggleFav(_currentReciter);
              if (mounted) setState(() => _isFav = !_isFav);
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (c, a) =>
                    ScaleTransition(scale: a, child: c),
                child: Icon(
                  key: ValueKey(_isFav),
                  _isFav ? Icons.favorite : Icons.favorite_border,
                  color: _isFav ? AppTheme.accentGold : Colors.white54,
                  size: 24,
                ),
              ),
            ),
          ),
        ]),
      );

  Widget _downloadBtn() {
    switch (_dlState.status) {
      case DownloadStatus.downloading:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(
              value: _dlState.progress,
              color: AppTheme.accentGold,
              strokeWidth: 2.5,
            ),
          ),
        );
      case DownloadStatus.done:
        return IconButton(
          icon: const Icon(Icons.download_done_rounded,
              color: AppTheme.accentGold, size: 22),
          onPressed: _toggleDownload,
        );
      case DownloadStatus.error:
        return IconButton(
          icon: const Icon(Icons.error_outline,
              color: AppTheme.errorColor, size: 22),
          onPressed: _toggleDownload,
        );
      default:
        return IconButton(
          icon: const Icon(Icons.download_outlined,
              color: Colors.white54, size: 22),
          onPressed: _toggleDownload,
        );
    }
  }

  // ── Scrollable Verses List ─────────────────────────────────────────────────
  Widget _buildVersesList() {
    if (_loadingAyahs) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentGold, strokeWidth: 2),
      );
    }
    if (_ayahs.isEmpty) {
      return const Center(
        child: Text('Verses unavailable',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      itemCount: _ayahs.length,
      itemBuilder: (context, i) {
        final isActive = i == _activeAyahIndex;
        return Padding(
          key: _ayahKeys[i],
          padding: const EdgeInsets.only(bottom: 24),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: isActive ? 24 : 20,
              height: 1.8,
              fontFamily: 'Amiri', // Or default if not loaded
              color: isActive ? AppTheme.accentGold : AppTheme.textMuted,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            child: Text(
              '${_ayahs[i]} ﴿${i + 1}﴾',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      },
    );
  }

  // ── Track Info ─────────────────────────────────────────────────────────────
  Widget _buildTrackInfo() => Padding(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 8),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  key: ValueKey(_currentReciter.surahEnglishName),
                  _currentReciter.surahEnglishName,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Text(_currentReciter.name,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
            ]),
          ),
          Text(
            _currentReciter.surahName,
            style: TextStyle(
                color: AppTheme.accentGold.withValues(alpha: 0.85),
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
        ]),
      );

  // ── Slider / Progress ──────────────────────────────────────────────────────
  Widget _buildSlider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: AppTheme.accentGold,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
              thumbColor: AppTheme.goldLight,
              overlayColor: AppTheme.accentGold.withValues(alpha: 0.15),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: _progress,
              onChangeStart: (_) => setState(() => _seeking = true),
              onChanged: (v) => setState(() => _position = Duration(
                  milliseconds: (v * _duration.inMilliseconds).round())),
              onChangeEnd: (v) {
                setState(() => _seeking = false);
                widget.handler.seek(Duration(
                    milliseconds:
                        (v * _duration.inMilliseconds).round()));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmt(_position),
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                  Text(_fmt(_duration),
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                ]),
          ),
        ]),
      );

  // ── Controls ───────────────────────────────────────────────────────────────
  Widget _buildControls() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Repeat
              _ctrlBtn(
                size: 44,
                color: _isRepeat
                    ? AppTheme.accentGold.withValues(alpha: 0.15)
                    : Colors.transparent,
                child: Icon(Icons.repeat_rounded,
                    color: _isRepeat
                        ? AppTheme.accentGold
                        : AppTheme.textMuted,
                    size: 22),
                onTap: () async {
                  final v = !_isRepeat;
                  setState(() => _isRepeat = v);
                  await widget.handler.setLoopMode(v);
                },
                isCircle: true,
              ),

              // Previous
              _ctrlBtn(
                size: 50,
                color: AppTheme.surfaceCard,
                child: Icon(Icons.skip_previous_rounded,
                    color: _hasPrev
                        ? AppTheme.textSecondary
                        : AppTheme.textMuted.withValues(alpha: 0.3),
                    size: 26),
                onTap: _hasPrev ? _goPrev : null,
                isCircle: true,
              ),

              // Play / Pause — large gold button
              ScaleTap(
                onTap: () => _isPlaying
                    ? widget.handler.pause()
                    : widget.handler.play(),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.goldGradient,
                    boxShadow: AppTheme.goldGlow(opacity: 0.45, blur: 20),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (c, a) =>
                        ScaleTransition(scale: a, child: c),
                    child: Icon(
                      key: ValueKey(_isPlaying),
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 36,
                    ),
                  ),
                ),
              ),

              // Next
              _ctrlBtn(
                size: 50,
                color: AppTheme.surfaceCard,
                child: Icon(Icons.skip_next_rounded,
                    color: _hasNext
                        ? AppTheme.textSecondary
                        : AppTheme.textMuted.withValues(alpha: 0.3),
                    size: 26),
                onTap: _hasNext ? _goNext : null,
                isCircle: true,
              ),

              // Forward 10 s
              _ctrlBtn(
                size: 44,
                color: Colors.transparent,
                child: const Icon(Icons.forward_10_rounded,
                    color: AppTheme.textMuted, size: 22),
                onTap: () {
                  final t = _position + const Duration(seconds: 10);
                  widget.handler
                      .seek(t > _duration ? _duration : t);
                },
                isCircle: true,
              ),
            ]),
      );

  Widget _ctrlBtn({
    required double size,
    required Color color,
    required Widget child,
    required VoidCallback? onTap,
    bool isCircle = false,
  }) =>
      ScaleTap(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          ),
          child: Center(child: child),
        ),
      );
}

// ─── Waveform Painter (kept for potential reuse) ──────────────────────────────
class WavePainter extends CustomPainter {
  final double progress;
  final double animValue;
  final int barCount;
  final Color activeColor;
  final Color inactiveColor;

  static final _rng = math.Random(42);
  static late final List<double> _heights;
  static bool _init = false;

  WavePainter({
    required this.progress,
    required this.animValue,
    required this.barCount,
    required this.activeColor,
    required this.inactiveColor,
  }) {
    if (!_init) {
      _heights = List.generate(barCount, (_) => 0.25 + _rng.nextDouble() * 0.75);
      _init = true;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bw   = (size.width - (barCount - 1) * 3) / barCount;
    final maxH = size.height;
    for (int i = 0; i < barCount; i++) {
      final active = (i / barCount) <= progress;
      final wave   = active
          ? math.sin((i / barCount * math.pi * 2) + animValue * math.pi * 2) * 0.15
          : 0.0;
      final h = (_heights[i] + wave).clamp(0.15, 1.0) * maxH;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                i * (bw + 3), (maxH - h) / 2, bw, h),
            const Radius.circular(2)),
        Paint()
          ..color = active ? activeColor : inactiveColor
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(WavePainter old) =>
      old.progress != progress || old.animValue != animValue;
}
