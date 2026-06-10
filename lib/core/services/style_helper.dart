class StyleHelper {
  static dynamic scaleTextSize(dynamic textSize, double fontSize) {
    if (fontSize == 1.0) return textSize;

    dynamic scaleValue(dynamic val) {
      if (val is num) {
        return val * fontSize;
      } else if (val is Map) {
        final stops = val['stops'];
        if (stops is List) {
          final newStops = [];
          for (final stop in stops) {
            if (stop is List && stop.length == 2) {
              final zoom = stop[0];
              final stopVal = stop[1];
              newStops.add([zoom, scaleValue(stopVal)]);
            } else {
              newStops.add(stop);
            }
          }
          return {...val, 'stops': newStops};
        }
      } else if (val is List) {
        if (val.isNotEmpty) {
          final op = val[0];
          final newList = List<dynamic>.from(val);
          if (op == 'case') {
            for (var i = 1; i < newList.length - 1; i += 2) {
              newList[i + 1] = scaleValue(newList[i + 1]);
            }
            if (newList.length % 2 == 0) {
              newList[newList.length - 1] = scaleValue(newList[newList.length - 1]);
            }
            return newList;
          } else if (op == 'match') {
            for (var i = 2; i < newList.length - 1; i += 2) {
              newList[i + 1] = scaleValue(newList[i + 1]);
            }
            if (newList.length % 2 != 0) {
              newList[newList.length - 1] = scaleValue(newList[newList.length - 1]);
            }
            return newList;
          } else if (op == 'interpolate' || op == 'step') {
            if (op == 'interpolate') {
              for (var i = 3; i < newList.length; i += 2) {
                if (i + 1 < newList.length) {
                  newList[i + 1] = scaleValue(newList[i + 1]);
                }
              }
            } else {
              newList[2] = scaleValue(newList[2]);
              for (var i = 4; i < newList.length; i += 2) {
                newList[i] = scaleValue(newList[i]);
              }
            }
            return newList;
          }
        }
      }
      return val;
    }

    return scaleValue(textSize);
  }

  static void scaleLayers(Map<String, dynamic> styleMap, double fontSize) {
    final layers = styleMap['layers'];
    if (layers is List) {
      for (var i = 0; i < layers.length; i++) {
        final layer = layers[i];
        if (layer is Map<String, dynamic>) {
          final layout = layer['layout'];
          if (layout is Map<String, dynamic>) {
            final textSize = layout['text-size'];
            if (textSize != null) {
              layout['text-size'] = scaleTextSize(textSize, fontSize);
            }
          }
        }
      }
    }
  }
}
