import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/services/sprite_cache.dart';
import 'package:stork/core/widgets/sprite_icon.dart';

/// A standard 1×1 fully transparent PNG (test fixture).
final Uint8List kTransparentPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// Sprite cache that returns a fixed [image] for every frame, so the widget
/// test does not depend on real asset decoding or timing.
class _FakeSpriteCache implements SpriteCache {
  _FakeSpriteCache(this.image);

  final ui.Image image;

  @override
  Future<ui.Image> loadFrame(String frameId, {required double scale}) async =>
      image;
}

void main() {
  testWidgets('SpriteIcon renders the requested frame at the given size', (
    tester,
  ) async {
    // Decode the test image once (needs the real async engine), then let the
    // widget test run deterministically with an already-completed future.
    final image = await tester.runAsync(_decodeTransparentImage);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spriteCacheProvider.overrideWithValue(_FakeSpriteCache(image!)),
        ],
        child: const MaterialApp(
          home: Center(
            child: SpriteIcon(frameId: 'poi-icon-home', width: 44, height: 44),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rawImage = tester.widget<RawImage>(find.byType(RawImage));
    expect(rawImage.image, same(image));
    expect(rawImage.width, 44);
    expect(rawImage.height, 44);
  });
}

Future<ui.Image> _decodeTransparentImage() async {
  final codec = await ui.instantiateImageCodec(kTransparentPng);
  try {
    final frame = await codec.getNextFrame();
    return frame.image;
  } finally {
    codec.dispose();
  }
}
