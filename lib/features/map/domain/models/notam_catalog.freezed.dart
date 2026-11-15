// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notam_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NotamCatalog {

 List<({String icao, Geographic position,})> get airports; List<({String icao, List<NotamPolygon> polygons,})> get areas;
/// Create a copy of NotamCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotamCatalogCopyWith<NotamCatalog> get copyWith => _$NotamCatalogCopyWithImpl<NotamCatalog>(this as NotamCatalog, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as NotamCatalog;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotamCatalog&&const DeepCollectionEquality().equals(other.airports, _this.airports)&&const DeepCollectionEquality().equals(other.areas, _this.areas));
}


@override
int get hashCode {
  final _this = this as NotamCatalog;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.airports),const DeepCollectionEquality().hash(_this.areas));
}

@override
String toString() {
  final _this = this as NotamCatalog;
  return 'NotamCatalog(airports: ${_this.airports}, areas: ${_this.areas})';
}


}

/// @nodoc
abstract mixin class $NotamCatalogCopyWith<$Res>  {
  factory $NotamCatalogCopyWith(NotamCatalog value, $Res Function(NotamCatalog) _then) = _$NotamCatalogCopyWithImpl;
@useResult
$Res call({
 List<({String icao, Geographic position,})> airports, List<({String icao, List<NotamPolygon> polygons,})> areas
});




}
/// @nodoc
class _$NotamCatalogCopyWithImpl<$Res>
    implements $NotamCatalogCopyWith<$Res> {
  _$NotamCatalogCopyWithImpl(this._self, this._then);

  final NotamCatalog _self;
  final $Res Function(NotamCatalog) _then;

/// Create a copy of NotamCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? airports = null,Object? areas = null,}) {
  return _then(NotamCatalog(
null == airports ? _self.airports : airports // ignore: cast_nullable_to_non_nullable
as List<({String icao, Geographic position,})>,null == areas ? _self.areas : areas // ignore: cast_nullable_to_non_nullable
as List<({String icao, List<NotamPolygon> polygons,})>,
  ));
}

}


/// Adds pattern-matching-related methods to [NotamCatalog].
extension NotamCatalogPatterns on NotamCatalog {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotamCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotamCatalog() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotamCatalog value)  $default,){
final _that = this;
switch (_that) {
case _NotamCatalog():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotamCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _NotamCatalog() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<({String icao, Geographic position,})> airports,  List<({String icao, List<NotamPolygon> polygons,})> areas)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotamCatalog() when $default != null:
return $default(_that.airports,_that.areas);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<({String icao, Geographic position,})> airports,  List<({String icao, List<NotamPolygon> polygons,})> areas)  $default,) {final _that = this;
switch (_that) {
case _NotamCatalog():
return $default(_that.airports,_that.areas);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<({String icao, Geographic position,})> airports,  List<({String icao, List<NotamPolygon> polygons,})> areas)?  $default,) {final _that = this;
switch (_that) {
case _NotamCatalog() when $default != null:
return $default(_that.airports,_that.areas);case _:
  return null;

}
}

}

/// @nodoc


class _NotamCatalog implements NotamCatalog {
  const _NotamCatalog( List<({String icao, Geographic position,})> airports,  List<({String icao, List<NotamPolygon> polygons,})> areas): _airports = airports,_areas = areas;
  

 final  List<({String icao, Geographic position,})> _airports;
@override List<({String icao, Geographic position,})> get airports {
  if (_airports is EqualUnmodifiableListView) return _airports;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_airports);
}

 final  List<({String icao, List<NotamPolygon> polygons,})> _areas;
@override List<({String icao, List<NotamPolygon> polygons,})> get areas {
  if (_areas is EqualUnmodifiableListView) return _areas;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_areas);
}


/// Create a copy of NotamCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotamCatalogCopyWith<_NotamCatalog> get copyWith => __$NotamCatalogCopyWithImpl<_NotamCatalog>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotamCatalog&&const DeepCollectionEquality().equals(other.airports, _airports)&&const DeepCollectionEquality().equals(other.areas, _areas));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_airports),const DeepCollectionEquality().hash(_areas));
}

@override
String toString() {
    return 'NotamCatalog(airports: $airports, areas: $areas)';
}


}

/// @nodoc
abstract mixin class _$NotamCatalogCopyWith<$Res> implements $NotamCatalogCopyWith<$Res> {
  factory _$NotamCatalogCopyWith(_NotamCatalog value, $Res Function(_NotamCatalog) _then) = __$NotamCatalogCopyWithImpl;
@override @useResult
$Res call({
 List<({String icao, Geographic position,})> airports, List<({String icao, List<NotamPolygon> polygons,})> areas
});




}
/// @nodoc
class __$NotamCatalogCopyWithImpl<$Res>
    implements _$NotamCatalogCopyWith<$Res> {
  __$NotamCatalogCopyWithImpl(this._self, this._then);

  final _NotamCatalog _self;
  final $Res Function(_NotamCatalog) _then;

/// Create a copy of NotamCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? airports = null,Object? areas = null,}) {
  return _then(_NotamCatalog(
null == airports ? _self._airports : airports // ignore: cast_nullable_to_non_nullable
as List<({String icao, Geographic position,})>,null == areas ? _self._areas : areas // ignore: cast_nullable_to_non_nullable
as List<({String icao, List<NotamPolygon> polygons,})>,
  ));
}


}

// dart format on
