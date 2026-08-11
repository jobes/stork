import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/sprite_cache.dart';

part 'sprite_icon.g.dart';

/// Provides the shared [SpriteCache] used by [SpriteIcon]. The cache is created
/// once and lives for the lifetime of the app, so cropped frames are reused.
@Riverpod(keepAlive: true)
SpriteCache spriteCache(Ref ref) => SpriteCache();

/// Renders a single frame from the app MapLibre sprite
/// (`assets/map_sprites/`, sprite id "default").
///
/// The map already renders every icon from this sprite; the Flutter UI
/// (favourite points, dialogs, …) uses [SpriteIcon] as well so it shares the
/// exact same icon art instead of bundling duplicate per-icon PNGs.
///
/// The requested frame is cropped out of the sprite sheet at a density that
/// matches the device pixel ratio. Decoded frames are cached for the lifetime
/// of the app (see [SpriteCache]).
///
/// Provide [width] and/or [height] for a stable layout: while the frame loads
/// a placeholder of that size is shown, so lists and rows do not jump. When
/// both are null the widget collapses to zero until the frame is ready and
/// then sizes itself to the frame's intrinsic size.
class SpriteIcon extends ConsumerWidget {
  const SpriteIcon({
    super.key,
    required this.frameId,
    this.width,
    this.height,
    this.color,
  });

  /// Sprite frame id, e.g. `poi-icon-home` or `traffic-icon-glider`.
  final String frameId;

  /// Target display width. When null the frame is shown at its native size.
  final double? width;

  /// Target display height. When null the frame is shown at its native size.
  final double? height;

  /// Optional tint applied to the frame (needed for the monochrome SDF
  /// traffic silhouettes, which are stored as white shapes).
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pick the sprite density from the display so the icon stays crisp on
    // high-DPI screens.
    final scale = SpriteCache.scaleForDevicePixelRatio(
      MediaQuery.devicePixelRatioOf(context),
    );
    final cache = ref.watch(spriteCacheProvider);
    return FutureBuilder<ui.Image>(
      future: cache.loadFrame(frameId, scale: scale),
      builder: (context, snapshot) {
        final image = snapshot.data;
        if (image == null) {
          // Reserve the requested size while loading so the layout does not
          // jump. All UI sprite frames are square, so a single dimension is
          // enough to reserve the correct area.
          final size = width ?? height ?? 0.0;
          return SizedBox(width: width ?? size, height: height ?? size);
        }
        return RawImage(
          image: image,
          width: width,
          height: height,
          // When no explicit size is given, the frame is rendered at its
          // native logical size. The frame was cropped from a sprite sheet
          // matching the device pixel ratio, so the sprite scale must be
          // forwarded here or 2x frames would be drawn at double size.
          scale: scale,
          fit: BoxFit.contain,
          color: color,
          filterQuality: FilterQuality.medium,
        );
      },
    );
  }
}
