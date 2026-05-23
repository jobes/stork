import 'package:freezed_annotation/freezed_annotation.dart';

part 'widget_position.freezed.dart';
part 'widget_position.g.dart';

@freezed
abstract class WidgetPosition with _$WidgetPosition {
  const factory WidgetPosition({
    required double top,
    required double left,
  }) = _WidgetPosition;

  factory WidgetPosition.fromJson(Map<String, dynamic> json) =>
      _$WidgetPositionFromJson(json);
}
