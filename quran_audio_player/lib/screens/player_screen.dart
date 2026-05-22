import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/surah_model.dart';
import '../services/quran_api_service.dart';
import '../services/firestore_service.dart';
import '../services/biometric_service.dart';
import '../services/audio_handler.dart';
import '../services/download_service.dart';
import '../services/resume_service.dart';
import '../utils/app_theme.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/scale_tap.dart';
import 'audio_player_page.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  List<Surah> _surahs   = [];
  List<Surah> _filtered = [];
  bool _loadingList     = true;
  bool _isPlaying       = false;
  Reciter? _currentReciter;
  Set<String> _favouriteIds = {};
  Duration _position = Duration.zero;
  DateTime? _lastPlayTime;

  Map<String, dynamic>? _resumeData;

  late QuranAudioHandler _handler;
  final TextEditingController _search = TextEditingController();

  Timer? _heartbeatTimer;
  StreamSubscription? _posSub, _stateSub, _favSub;

  @override
  void initState() {
    super.initState();
    _handler = audioHandler as QuranAudioHandler;
    _loadSurahs();
    _loadResumeData();
    _listen();
    _startHeartbeat();
    _search.addListener(_onSearch);
  }

  // ── Search ─────────────────────────────────────────────────────────────────
  void _onSearch() {
    final q = _search.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _surahs
          : _surahs
              .where((s) =>
                  s.englishName.toLowerCase().contains(q) ||
                  s.name.contains(q) ||
                  s.id.toString() == q)
              .toList();
    });
  }

  // ── Resume ─────────────────────────────────────────────────────────────────
  Future<void> _loadResumeData() async {
    final data = await ResumeService.load();
    if (mounted) setState(() => _resumeData = data);
  }

  // ── Heartbeat — save stats + position every 20 s ──────────────────────────
  void _syncStats() {
    if (_lastPlayTime != null && _currentReciter != null) {
      final now = DateTime.now();
      final diff = now.difference(_lastPlayTime!).inSeconds;
      if (diff > 0) {
        FirestoreService.addListeningSeconds(diff);
        ResumeService.save(
          url:               _currentReciter!.audioUrl,
          positionMs:        _position.inMilliseconds,
          surahName:         _currentReciter!.surahName,
          surahEnglishName:  _currentReciter!.surahEnglishName,
          reciterName:       _currentReciter!.name,
          surahId:           _currentReciter!.surahId,
          reciterId:         _currentReciter!.id,
        );
      }
      _lastPlayTime = _isPlaying ? now : null;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_isPlaying) _syncStats();
    });
  }

  // ── Streams ────────────────────────────────────────────────────────────────
  void _listen() {
    _posSub = _handler.positionStream
        .listen((p) => setState(() => _position = p));
    _stateSub = _handler.playerStateStream.listen((s) {
      if (mounted && s.playing != _isPlaying) {
        if (s.playing) {
          _lastPlayTime = DateTime.now();
        } else {
          _syncStats();
        }
        setState(() => _isPlaying = s.playing);
      }
    });
    _favSub = FirestoreService.favouritesStream().listen((favs) {
      if (mounted) {
        setState(() =>
            _favouriteIds = favs.map((r) => r.favouriteId).toSet());
      }
    });
  }

  Future<void> _loadSurahs() async {
    final list = await QuranApiService.fetchSurahs();
    if (mounted) {
      setState(() {
        _surahs     = list;
        _filtered   = list;
        _loadingList = false;
      });
    }
  }

  Future<void> _toggleFav(Reciter r) async {
    if (_favouriteIds.contains(r.favouriteId)) {
      if (await BiometricService.authenticate(reason: 'Verify to remove')) {
        await FirestoreService.removeFavourite(r.favouriteId);
      }
    } else {
      await FirestoreService.addFavourite(r);
    }
  }

  // ── Play & open full-screen player ────────────────────────────────────────
  Future<void> _playAndOpen(Reciter r, {Duration? seekTo}) async {
    setState(() => _currentReciter = r);
    await FirestoreService.incrementPlayCount(r);

    // Prefer local file if downloaded
    final local = await DownloadService.getLocalPath(r.audioUrl);
    final url   = local != null ? 'file://$local' : r.audioUrl;

    if (seekTo != null && seekTo > Duration.zero) {
      await _handler.playUrlAtPosition(
          url,
          MediaItem(id: url, title: r.surahEnglishName, artist: r.name),
          seekTo);
    } else {
      await _handler.playUrl(
          url,
          MediaItem(id: url, title: r.surahEnglishName, artist: r.name));
    }

    final index = _surahs.indexWhere((s) => s.id == r.surahId);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AudioPlayerPage(
            reciter:          r,
            handler:          _handler,
            isFavourite:      _favouriteIds.contains(r.favouriteId),
            onToggleFav:      _toggleFav,
            surahs:           _surahs,
            initialSurahIndex: index >= 0 ? index : 0,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    if (_isPlaying) _syncStats();
    _heartbeatTimer?.cancel();
    _posSub?.cancel();
    _stateSub?.cancel();
    _favSub?.cancel();
    _search.dispose();
    super.dispose();
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        // ── Continue Listening card ──────────────────────────────────────
        if (_resumeData != null) _buildResumeCard(),

        // ── Search bar ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _search,
            style: const TextStyle(color: AppTheme.primaryText, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search surah name or number…',
              hintStyle:
                  TextStyle(color: AppTheme.textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search,
                  color: AppTheme.textSecondary, size: 20),
              suffixIcon: _search.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _search.clear();
                        setState(() => _filtered = _surahs);
                      },
                      child: const Icon(Icons.close,
                          color: AppTheme.textSecondary, size: 18),
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppTheme.accentGold, width: 1.5),
              ),
            ),
          ),
        ),

        // ── Surah list ───────────────────────────────────────────────────
        Expanded(
          child: _loadingList
              ? const SurahShimmerList()
              : _filtered.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        const Icon(Icons.search_off,
                            color: AppTheme.textMuted, size: 40),
                        const SizedBox(height: 12),
                        Text('No surahs found',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 15)),
                      ]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) => _SurahTile(
                        surah:          _filtered[i],
                        favouriteIds:   _favouriteIds,
                        currentReciter: _currentReciter,
                        isPlaying:      _isPlaying,
                        onToggleFav:    _toggleFav,
                        onPlay:         _playAndOpen,
                      ),
                    ),
        ),
      ]),
    );
  }

  // ── Continue Listening Card ────────────────────────────────────────────────
  Widget _buildResumeCard() {
    final data = _resumeData!;
    return GestureDetector(
      onTap: () async {
        final r = Reciter(
          id:               data['reciterId']       as int,
          name:             data['reciterName']      as String,
          audioUrl:         data['url']              as String,
          surahId:          data['surahId']          as int,
          surahName:        data['surahName']        as String,
          surahEnglishName: data['surahEnglishName'] as String,
        );
        setState(() => _resumeData = null);
        await ResumeService.clear();
        await _playAndOpen(r,
            seekTo: Duration(milliseconds: data['positionMs'] as int));
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3E2C23), Color(0xFF5A4000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.accentGold.withValues(alpha: 0.28)),
          boxShadow: AppTheme.goldGlow(opacity: 0.1, blur: 14),
        ),
        child: Row(children: [
          // Play icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.black, size: 24),
          ),
          const SizedBox(width: 12),

          // Text
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Text('CONTINUE LISTENING',
                  style: TextStyle(
                      color: AppTheme.accentGold,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              const SizedBox(height: 3),
              Text(data['surahEnglishName'] as String,
                  style: const TextStyle(
                      color: AppTheme.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(data['reciterName'] as String,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11)),
            ]),
          ),

          // Dismiss
          GestureDetector(
            onTap: () async {
              await ResumeService.clear();
              setState(() => _resumeData = null);
            },
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close,
                  color: AppTheme.textMuted, size: 18),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Surah Expansion Tile ─────────────────────────────────────────────────────
class _SurahTile extends StatelessWidget {
  final Surah surah;
  final Set<String> favouriteIds;
  final Reciter? currentReciter;
  final bool isPlaying;
  final Future<void> Function(Reciter) onToggleFav;
  final Future<void> Function(Reciter, {Duration? seekTo}) onPlay;

  const _SurahTile({
    required this.surah,
    required this.favouriteIds,
    required this.currentReciter,
    required this.isPlaying,
    required this.onToggleFav,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.cardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text('${surah.id}',
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 12)),
              ),
            ),
            title: Text(surah.englishName,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.primaryText)),
            subtitle: Text(surah.name,
                style: const TextStyle(
                    color: AppTheme.accentGold,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            iconColor: AppTheme.textSecondary,
            collapsedIconColor: AppTheme.textMuted,
            children: surah.reciters.map((r) {
              final isActive = currentReciter?.favouriteId == r.favouriteId;
              return ScaleTap(
                onTap: () => onPlay(r),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.accentGold.withValues(alpha: 0.10)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? AppTheme.accentGold.withValues(alpha: 0.35)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        key: ValueKey(isActive),
                        isActive
                            ? Icons.equalizer_rounded
                            : Icons.play_circle_outline_rounded,
                        color: isActive
                            ? AppTheme.accentGold
                            : AppTheme.textSecondary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(r.name,
                            style: TextStyle(
                              color: isActive
                                  ? AppTheme.primaryText
                                  : AppTheme.textSecondary,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontSize: 13,
                            )),
                        const SizedBox(height: 2),
                        const Text('Tap to open player',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 10)),
                      ]),
                    ),
                    ValueListenableBuilder<Set<String>>(
                      valueListenable: DownloadService.downloadedUrls,
                      builder: (context, downloaded, child) {
                        if (downloaded.contains(r.audioUrl)) {
                          return const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(Icons.download_done_rounded,
                                color: AppTheme.accentGold, size: 18),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                    GestureDetector(
                      onTap: () => onToggleFav(r),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (c, a) =>
                            ScaleTransition(scale: a, child: c),
                        child: Icon(
                          key: ValueKey(favouriteIds.contains(r.favouriteId)),
                          favouriteIds.contains(r.favouriteId)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: favouriteIds.contains(r.favouriteId)
                              ? AppTheme.accentGold // Changed from error to gold
                              : AppTheme.textMuted,
                          size: 20,
                        ),
                      ),
                    ),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}