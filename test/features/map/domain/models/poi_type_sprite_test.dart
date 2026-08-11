import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/map/domain/models/poi_type.dart';

import '../../../../helpers/sprite_test_utils.dart';

void main() {
  test('Every PoiType has a sprite frame that fits the sheet', () {
    final index = loadSpriteIndex();
    for (final type in PoiType.values) {
      expect(
        index.containsKey(type.mapIconId),
        isTrue,
        reason: 'Sprite frame missing: ${type.mapIconId}',
      );
    }
    expect(
      overflowingFrames(index),
      isEmpty,
      reason: 'Some sprite frames overflow the sheet',
    );
  });
}
