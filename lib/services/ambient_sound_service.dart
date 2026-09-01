import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

enum AmbientTrack { rain, forest, whiteNoise, none }

class AmbientSoundService with WidgetsBindingObserver {
  static final AmbientSoundService _instance = AmbientSoundService._internal();
  factory AmbientSoundService() => _instance;
  AmbientSoundService._internal();

  AudioPlayer _currentPlayer = AudioPlayer();
  AudioPlayer _standbyPlayer = AudioPlayer();
  AmbientTrack _currentTrack = AmbientTrack.none;
  double _volume = 0.5;
  Timer? _crossfadeTimer;
  bool _wasPlayingBeforeBackground = false;
  bool _isObserverAdded = false;

  AmbientTrack get currentTrack => _currentTrack;
  double get volume => _volume;
  bool get isPlaying => _currentTrack != AmbientTrack.none;

  static const Map<AmbientTrack, String> _trackPaths = {
    AmbientTrack.rain: 'assets/audio/rain.mp3',
    AmbientTrack.forest: 'assets/audio/forest.mp3',
    AmbientTrack.whiteNoise: 'assets/audio/whitenoise.mp3',
  };

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _wasPlayingBeforeBackground = isPlaying;
      stop();
    } else if (state == AppLifecycleState.resumed) {
      if (_wasPlayingBeforeBackground && _currentTrack == AmbientTrack.none) {
        _wasPlayingBeforeBackground = false;
      }
    }
  }

  Future<void> play(AmbientTrack track) async {
    if (track == _currentTrack && _currentPlayer.state == PlayerState.playing) return;

    if (!_isObserverAdded) {
      WidgetsBinding.instance.addObserver(this);
      _isObserverAdded = true;
    }

    final path = _trackPaths[track];
    if (path == null) return;

    _crossfadeTimer?.cancel();

    final isFirstTrack = _currentTrack == AmbientTrack.none || _currentPlayer.state != PlayerState.playing;

    _currentTrack = track;

    if (isFirstTrack) {
      await _standbyPlayer.stop();
      await _standbyPlayer.setSource(AssetSource(path.replaceFirst('assets/', '')));
      await _standbyPlayer.setVolume(_volume);
      await _standbyPlayer.setReleaseMode(ReleaseMode.loop);
      await _standbyPlayer.resume();
      final tmp = _currentPlayer;
      _currentPlayer = _standbyPlayer;
      _standbyPlayer = tmp;
      return;
    }

    await _standbyPlayer.stop();
    await _standbyPlayer.setSource(AssetSource(path.replaceFirst('assets/', '')));
    await _standbyPlayer.setVolume(0.0);
    await _standbyPlayer.setReleaseMode(ReleaseMode.loop);
    await _standbyPlayer.resume();

    final oldPlayer = _currentPlayer;
    final oldVolume = _volume;
    const int crossfadeMs = 800;
    const int steps = 30;
    const int intervalMs = crossfadeMs ~/ steps;
    int step = 0;

    _crossfadeTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) async {
      step++;
      final progress = step / steps;
      await oldPlayer.setVolume((oldVolume * (1 - progress)).clamp(0.0, 1.0));
      await _standbyPlayer.setVolume((_volume * progress).clamp(0.0, 1.0));

      if (step >= steps) {
        timer.cancel();
        await oldPlayer.stop();
        _currentPlayer = _standbyPlayer;
        _standbyPlayer = oldPlayer;
      }
    });
  }

  Future<void> stop() async {
    _crossfadeTimer?.cancel();
    await _currentPlayer.stop();
    await _standbyPlayer.stop();
    _currentTrack = AmbientTrack.none;
  }

  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    await _currentPlayer.setVolume(_volume);
  }

  Future<void> dispose() async {
    if (_isObserverAdded) {
      WidgetsBinding.instance.removeObserver(this);
      _isObserverAdded = false;
    }
    _crossfadeTimer?.cancel();
    await _currentPlayer.dispose();
    await _standbyPlayer.dispose();
  }
}
