import 'package:flutter/material.dart';
import '../services/ambient_sound_service.dart';

class PomodoroAmbientToggle extends StatefulWidget {
  const PomodoroAmbientToggle({super.key});

  @override
  State<PomodoroAmbientToggle> createState() => _PomodoroAmbientToggleState();
}

class _PomodoroAmbientToggleState extends State<PomodoroAmbientToggle> {
  final AmbientSoundService _ambient = AmbientSoundService();

  static const _tracks = [
    AmbientTrack.none,
    AmbientTrack.rain,
    AmbientTrack.forest,
    AmbientTrack.whiteNoise,
  ];

  static const Map<AmbientTrack, IconData> _icons = {
    AmbientTrack.none: Icons.headphones_outlined,
    AmbientTrack.rain: Icons.water_drop,
    AmbientTrack.forest: Icons.park,
    AmbientTrack.whiteNoise: Icons.graphic_eq,
  };

  void _cycleTrack() {
    final currentIndex = _tracks.indexOf(_ambient.currentTrack);
    final nextIndex = (currentIndex + 1) % _tracks.length;
    final next = _tracks[nextIndex];

    if (next == AmbientTrack.none) {
      _ambient.stop();
    } else {
      _ambient.play(next);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _icons[_ambient.currentTrack] ?? Icons.headphones_outlined,
        color: _ambient.isPlaying ? Colors.white : Colors.white38,
        size: 22,
      ),
      onPressed: _cycleTrack,
    );
  }
}
