import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../core/mitzy_assets.dart';

/// The Mitzy mascot avatar rendered at [width] x [height].
///
/// When the Winter Arc season is active it adds the designed "winter_loop": a
/// gentle vertical float (a 3s loop hovering ~3% of the avatar's height, per
/// the asset manifest's `animation` spec). Out of season the image renders
/// statically so the pre-campaign look is unchanged.
///
/// When [assetPath] is null the current seasonal asset is resolved via
/// [MitzyAssets.resolve]. Pass [date] to pin the season (tests/preview);
/// defaults to now.
class MitzyAvatar extends StatefulWidget {
  const MitzyAvatar({
    super.key,
    this.assetPath,
    this.date,
    this.width = 56,
    this.height = 56,
    this.fit = BoxFit.contain,
    this.floatOffset = 0.03,
    this.duration = const Duration(seconds: 3),
  });

  /// The asset to render; resolved seasonally when null.
  final String? assetPath;

  /// The moment used for seasonal resolution; defaults to now.
  final DateTime? date;

  final double width;
  final double height;
  final BoxFit fit;

  /// Vertical float amplitude as a fraction of the avatar height.
  final double floatOffset;

  /// One full float cycle.
  final Duration duration;

  @override
  State<MitzyAvatar> createState() => _MitzyAvatarState();
}

class _MitzyAvatarState extends State<MitzyAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final bool _floatEnabled;

  @override
  void initState() {
    super.initState();
    _floatEnabled = MitzyAssets.isWinterActive(widget.date ?? DateTime.now());
    _floatController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (_floatEnabled) _floatController.repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Widget _buildImage(String path) {
    final image = Image.asset(
      path,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
    if (!_floatEnabled) return image;
    return AnimatedBuilder(
      animation: _floatController,
      child: image,
      builder: (context, child) {
        final phase = _floatController.value * math.pi * 2;
        return FractionalTranslation(
          translation: Offset(0, widget.floatOffset * math.sin(phase)),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.assetPath;
    if (path != null) return _buildImage(path);
    return FutureBuilder<String>(
      future: MitzyAssets.resolve(widget.date ?? DateTime.now()),
      initialData: MitzyAssets.standard,
      builder: (context, snapshot) =>
          _buildImage(snapshot.data ?? MitzyAssets.standard),
    );
  }
}