import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

// TODO: Separate out JustAudio code to another class?
class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);

  MyAudioHandler() {
    _loadEmptyPlaylist(); // TODO: Do we need to load an empty playlist?
    _notifyAudioServiceAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForCurrentSongIndexChanges();
  }

  // Catch-all for notifify AudioService about any Playback event states.
  void _notifyAudioServiceAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          // MediaControl.stop, // TODO: Decide if we do actually want a stop button.
          MediaControl.skipToNext,
          // TODO: Could we hide the previous/next buttons here when it's the
          //  first or last song respectively.

          // MediaControl.rewind // TODO: Try this out. Change rewind amount?
        ],
        systemActions: const {
          MediaAction.seek,
        },
        // androidCompactActionIndices: const [0, 1, 3], // Only needed if we have more than 3 MediaControls.
        /*
         * These refer to items in the control list that you want to show in
         * Android’s compact notification view. Since there are four controls
         * listed above (skipToPrevious, play/pause, stop, skipToNext),
         * [0, 1, 3] refers to skipToPrevious, play (or pause), and skipToNext.
         * The stop control is at index 2 and is excluded here.
         * // Max of 3.
         */
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    });
  }

  // TODO: Could probably change name to _initPlayerAudioSource (or something like that).
  Future<void> _loadEmptyPlaylist() async {
    try {
      // TODO: Pass in initialIndex and initialPosition if you want to continue
      //  from a previous position; which we will.
      await _player.setAudioSource(_playlist,
          initialIndex: 0, initialPosition: Duration.zero);
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    // manage Just Audio // This wants a ConcatenatingAudioSource of AudioSources
    final audioSource = mediaItems.map(_createAudioSource);
    _playlist.addAll(audioSource.toList());

    // notify system // This wants a list of MediaItems
    final newQueue = queue.value..addAll(mediaItems);

    // TODO: Can we simply call queue.add(mediaItems) instead???
    queue.add(newQueue);
  }

  UriAudioSource _createAudioSource(MediaItem mediaItem) {
    return AudioSource.uri(
      Uri.parse(mediaItem.extras!['url']),
      tag: mediaItem,
    );
  }

  // Note: Called from both AudioService and UI
  @override
  Future<void> play() => _player.play();

  // Note: Called from both AudioService and UI
  @override
  Future<void> pause() => _player.pause();

  // Note: Called from both AudioService and UI
  @override
  Future<void> seek(Duration position) => _player.seek(position);

  /*
   * Once you know the duration from Just Audio, you need to update the
   * MediaItem with the duration. And if you change a MediaItem, you also need
   * to update the playlist queue. It’s kind of a pain, but here is how you do that:
   */
  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      final index = _player.currentIndex;
      final newQueue = queue.value;
      if (index == null || newQueue.isEmpty) return;
      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    });
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  void _listenForCurrentSongIndexChanges() {
    _player.currentIndexStream.listen((index) {
      final playlist = queue.value;
      if (index == null || playlist.isEmpty) return;
      mediaItem.add(playlist[index]);
    });
  }

  @override
  Future<void> stop() async {
    await _player.dispose();
    return super.stop();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> fastForward() async {
    super.fastForward();
  }

  @override
  Future<void> rewind() async {
    super.rewind();
  }
}
