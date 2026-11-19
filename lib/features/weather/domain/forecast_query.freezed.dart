// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'forecast_query.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ForecastQuery {

 Map<String, ForecastLocation> get locations; DateTime get start; DateTime get end;





@override
String toString() {
  final _this = this as ForecastQuery;
  return 'ForecastQuery(locations: ${_this.locations}, start: ${_this.start}, end: ${_this.end})';
}


}





/// @nodoc


class _ForecastQuery extends ForecastQuery {
  const _ForecastQuery({required  Map<String, ForecastLocation> locations, required this.start, required this.end}): _locations = locations,super._();
  

 final  Map<String, ForecastLocation> _locations;
@override Map<String, ForecastLocation> get locations {
  if (_locations is EqualUnmodifiableMapView) return _locations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_locations);
}

@override final  DateTime start;
@override final  DateTime end;






@override
String toString() {
    return 'ForecastQuery._value(locations: $locations, start: $start, end: $end)';
}


}




// dart format on
