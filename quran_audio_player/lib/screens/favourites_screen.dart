import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../services/firestore_service.dart';
import '../services/biometric_service.dart';
import '../services/download_service.dart';
import '../services/quran_api_service.dart';
import '../services/audio_handler.dart';
import '../models/surah_model.dart';
import '../utils/app_theme.dart';
import '../main.dart';
import 'audio_player_page.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};
  List<Surah> _allSurahs = [];

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    final s = await QuranApiService.fetchSurahs();
    if (mounted) setState(() => _allSurahs = s);
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (await BiometricService.authenticate(reason: 'Required to delete favorites')) {
      for (final id in _selectedIds) {
        await FirestoreService.removeFavourite(id);
      }
      setState(() {
        _selectedIds.clear();
        _selectionMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: TabBar(
            indicatorColor: AppTheme.accentGold,
            labelColor: AppTheme.accentGold,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Favourites'),
              Tab(text: 'Downloads'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFavouritesTab(),
            _buildDownloadsTab(),
          ],
        ),
      ),
    );
  }

  // ─── FAVOURITES TAB ──────────────────────────────────────────────────────────
  Widget _buildFavouritesTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Reciter>>(
            stream: FirestoreService.favouritesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.accentGold),
                );
              }
              final favs = snapshot.data ?? [];
              if (favs.isEmpty) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.surfaceCard,
                        border: Border.all(
                            color: AppTheme.accentGold.withValues(alpha: 0.2)),
                        boxShadow: AppTheme.goldGlow(opacity: 0.15, blur: 24),
                      ),
                      child: const Icon(Icons.favorite_outline,
                          color: AppTheme.accentGold, size: 36),
                    ),
                    const SizedBox(height: 20),
                    const Text('No saved surahs yet',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryText)),
                    const SizedBox(height: 8),
                    const Text('Tap ♥ to save your favorites.',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                  ]),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                itemCount: favs.length,
                itemBuilder: (context, i) {
                  final r = favs[i];
                  final isSelected = _selectedIds.contains(r.favouriteId);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onLongPress: () {
                        setState(() {
                          _selectionMode = true;
                          _selectedIds.add(r.favouriteId);
                        });
                      },
                      onTap: () async {
                        if (_selectionMode) {
                          _toggleSelection(r.favouriteId);
                        } else {
                          // Play audio logic
                          final local = await DownloadService.getLocalPath(r.audioUrl);
                          final url = local != null ? 'file://$local' : r.audioUrl;
                          final handler = audioHandler as QuranAudioHandler;
                          await handler.playUrl(url, MediaItem(
                              id: url, title: r.surahEnglishName, artist: r.name));
                          
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AudioPlayerPage(
                                  reciter: r,
                                  handler: handler,
                                  isFavourite: true,
                                  onToggleFav: (rec) async {
                                    await FirestoreService.removeFavourite(rec.favouriteId);
                                  },
                                  surahs: _allSurahs,
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: Dismissible(
                        key: Key(r.favouriteId),
                        direction: _selectionMode
                            ? DismissDirection.none
                            : DismissDirection.endToStart,
                        confirmDismiss: (_) async =>
                            BiometricService.authenticate(
                                reason: 'Required to remove from favorites'),
                        onDismissed: (_) =>
                            FirestoreService.removeFavourite(r.favouriteId),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.transparent,
                              AppTheme.errorColor.withValues(alpha: 0.25),
                            ]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Delete',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                        child: Container(
                          decoration: AppTheme.cardDecoration(),
                          child: Row(children: [
                            if (_selectionMode)
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Checkbox(
                                  value: isSelected,
                                  activeColor: AppTheme.errorColor,
                                  onChanged: (_) =>
                                      _toggleSelection(r.favouriteId),
                                ),
                              )
                            else
                              Container(
                                width: 4,
                                height: 68,
                                decoration: const BoxDecoration(
                                  gradient: AppTheme.goldGradient,
                                  borderRadius: BorderRadius.horizontal(
                                      left: Radius.circular(16)),
                                ),
                              ),
                            const SizedBox(width: 14),
                            // Avatar
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                gradient: AppTheme.goldGradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow:
                                    AppTheme.goldGlow(opacity: 0.3, blur: 10),
                              ),
                              child: const Icon(Icons.play_arrow,
                                  color: Colors.black, size: 22),
                            ),
                            const SizedBox(width: 14),
                            // Text
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(r.surahEnglishName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: AppTheme.primaryText)),
                                    const SizedBox(height: 3),
                                    Text(r.name,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary)),
                                  ]),
                            ),
                            // Heart Toggle
                            if (!_selectionMode)
                              GestureDetector(
                                onTap: () async {
                                  if (await BiometricService.authenticate(reason: 'Required to remove from favorites')) {
                                    await FirestoreService.removeFavourite(r.favouriteId);
                                  }
                                },
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 16, left: 16),
                                  child: Icon(Icons.favorite,
                                      color: AppTheme.accentGold, size: 22),
                                ),
                              ),
                          ]),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Bulk delete button
        if (_selectionMode)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.delete),
              label: Text('Delete Selected (${_selectedIds.length})',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
            ),
          ),
      ],
    );
  }

  // ─── DOWNLOADS TAB ───────────────────────────────────────────────────────────
  Widget _buildDownloadsTab() {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: DownloadService.downloadedUrls,
      builder: (context, downloadedUrls, child) {
        if (downloadedUrls.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.download_done_rounded,
                  color: AppTheme.textMuted, size: 48),
              const SizedBox(height: 20),
              const Text('No downloads yet',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryText)),
              const SizedBox(height: 8),
              const Text('Surahs you download will appear here',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ]),
          );
        }

        // Match downloaded URLs with Reciter info
        final downloadedReciters = <Reciter>[];
        for (final surah in _allSurahs) {
          for (final r in surah.reciters) {
            if (downloadedUrls.contains(r.audioUrl)) {
              downloadedReciters.add(r);
            }
          }
        }

        if (_allSurahs.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.accentGold));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          itemCount: downloadedReciters.length,
          itemBuilder: (context, i) {
            final r = downloadedReciters[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: AppTheme.cardDecoration(),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.play_arrow,
                        color: Colors.black, size: 22),
                  ),
                  title: Text(r.surahEnglishName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.primaryText)),
                  subtitle: Text(r.name,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppTheme.errorColor),
                    onPressed: () => DownloadService.delete(r.audioUrl),
                  ),
                  onTap: () async {
                    final local = await DownloadService.getLocalPath(r.audioUrl);
                    final url = local != null ? 'file://$local' : r.audioUrl;
                    final handler = audioHandler as QuranAudioHandler;
                    await handler.playUrl(url, MediaItem(
                        id: url, title: r.surahEnglishName, artist: r.name));
                    
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AudioPlayerPage(
                            reciter: r,
                            handler: handler,
                            isFavourite: false,
                            onToggleFav: (_) async {},
                            surahs: _allSurahs,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}