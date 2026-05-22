import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class QuranAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();

  QuranAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        stop();
      }
    });
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: {
        ProcessingState.idle:      AudioProcessingState.idle,
        ProcessingState.loading:   AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready:     AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
  }

  Future<void> playUrl(String url, MediaItem item) async {
    mediaItem.add(item);
    await _player.setUrl(url);
    play();
  }

  /// Loads a URL and seeks to [position] before playing.
  Future<void> playUrlAtPosition(
      String url, MediaItem item, Duration position) async {
    mediaItem.add(item);
    await _player.setUrl(url);
    await _player.seek(position);
    play();
  }

  @override Future<void> play()   => _player.play();
  @override Future<void> pause()  => _player.pause();
  @override Future<void> stop()   async { await _player.stop(); }
  @override Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setLoopMode(bool repeat) async {
    await _player.setLoopMode(repeat ? LoopMode.one : LoopMode.off);
  }

  AudioPlayer get player => _player;

  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
}
