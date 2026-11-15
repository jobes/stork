// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notam_repository.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NotamFetchResult {

 List<Notam> get notams; List<String> get failedLocations; List<String> get partialLocations; DateTime? get oldestFetch; DateTime? get nextRefresh; bool get isRefreshing;
/// Create a copy of NotamFetchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotamFetchResultCopyWith<NotamFetchResult> get copyWith => _$NotamFetchResultCopyWithImpl<NotamFetchResult>(this as NotamFetchResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as NotamFetchResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotamFetchResult&&const DeepCollectionEquality().equals(other.notams, _this.notams)&&const DeepCollectionEquality().equals(other.failedLocations, _this.failedLocations)&&const DeepCollectionEquality().equals(other.partialLocations, _this.partialLocations)&&(identical(other.oldestFetch, _this.oldestFetch) || other.oldestFetch == _this.oldestFetch)&&(identical(other.nextRefresh, _this.nextRefresh) || other.nextRefresh == _this.nextRefresh)&&(identical(other.isRefreshing, _this.isRefreshing) || other.isRefreshing == _this.isRefreshing));
}


@override
int get hashCode {
  final _this = this as NotamFetchResult;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.notams),const DeepCollectionEquality().hash(_this.failedLocations),const DeepCollectionEquality().hash(_this.partialLocations),_this.oldestFetch,_this.nextRefresh,_this.isRefreshing);
}

@override
String toString() {
  final _this = this as NotamFetchResult;
  return 'NotamFetchResult(notams: ${_this.notams}, failedLocations: ${_this.failedLocations}, partialLocations: ${_this.partialLocations}, oldestFetch: ${_this.oldestFetch}, nextRefresh: ${_this.nextRefresh}, isRefreshing: ${_this.isRefreshing})';
}


}

/// @nodoc
abstract mixin class $NotamFetchResultCopyWith<$Res>  {
  factory $NotamFetchResultCopyWith(NotamFetchResult value, $Res Function(NotamFetchResult) _then) = _$NotamFetchResultCopyWithImpl;
@useResult
$Res call({
 List<Notam> notams, List<String> failedLocations, List<String> partialLocations, DateTime? oldestFetch, DateTime? nextRefresh, bool isRefreshing
});




}
/// @nodoc
class _$NotamFetchResultCopyWithImpl<$Res>
    implements $NotamFetchResultCopyWith<$Res> {
  _$NotamFetchResultCopyWithImpl(this._self, this._then);

  final NotamFetchResult _self;
  final $Res Function(NotamFetchResult) _then;

/// Create a copy of NotamFetchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? notams = null,Object? failedLocations = null,Object? partialLocations = null,Object? oldestFetch = freezed,Object? nextRefresh = freezed,Object? isRefreshing = null,}) {
  return _then(NotamFetchResult(
null == notams ? _self.notams : notams // ignore: cast_nullable_to_non_nullable
as List<Notam>,failedLocations: null == failedLocations ? _self.failedLocations : failedLocations // ignore: cast_nullable_to_non_nullable
as List<String>,partialLocations: null == partialLocations ? _self.partialLocations : partialLocations // ignore: cast_nullable_to_non_nullable
as List<String>,oldestFetch: freezed == oldestFetch ? _self.oldestFetch : oldestFetch // ignore: cast_nullable_to_non_nullable
as DateTime?,nextRefresh: freezed == nextRefresh ? _self.nextRefresh : nextRefresh // ignore: cast_nullable_to_non_nullable
as DateTime?,isRefreshing: null == isRefreshing ? _self.isRefreshing : isRefreshing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NotamFetchResult].
extension NotamFetchResultPatterns on NotamFetchResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotamFetchResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotamFetchResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotamFetchResult value)  $default,){
final _that = this;
switch (_that) {
case _NotamFetchResult():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotamFetchResult value)?  $default,){
final _that = this;
switch (_that) {
case _NotamFetchResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Notam> notams,  List<String> failedLocations,  List<String> partialLocations,  DateTime? oldestFetch,  DateTime? nextRefresh,  bool isRefreshing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotamFetchResult() when $default != null:
return $default(_that.notams,_that.failedLocations,_that.partialLocations,_that.oldestFetch,_that.nextRefresh,_that.isRefreshing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Notam> notams,  List<String> failedLocations,  List<String> partialLocations,  DateTime? oldestFetch,  DateTime? nextRefresh,  bool isRefreshing)  $default,) {final _that = this;
switch (_that) {
case _NotamFetchResult():
return $default(_that.notams,_that.failedLocations,_that.partialLocations,_that.oldestFetch,_that.nextRefresh,_that.isRefreshing);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Notam> notams,  List<String> failedLocations,  List<String> partialLocations,  DateTime? oldestFetch,  DateTime? nextRefresh,  bool isRefreshing)?  $default,) {final _that = this;
switch (_that) {
case _NotamFetchResult() when $default != null:
return $default(_that.notams,_that.failedLocations,_that.partialLocations,_that.oldestFetch,_that.nextRefresh,_that.isRefreshing);case _:
  return null;

}
}

}

/// @nodoc


class _NotamFetchResult extends NotamFetchResult {
  const _NotamFetchResult( List<Notam> notams, { List<String> failedLocations = const <String>[],  List<String> partialLocations = const <String>[], this.oldestFetch, this.nextRefresh, this.isRefreshing = false}): _notams = notams,_failedLocations = failedLocations,_partialLocations = partialLocations,super._();
  

 final  List<Notam> _notams;
@override List<Notam> get notams {
  if (_notams is EqualUnmodifiableListView) return _notams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notams);
}

 final  List<String> _failedLocations;
@override@JsonKey() List<String> get failedLocations {
  if (_failedLocations is EqualUnmodifiableListView) return _failedLocations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_failedLocations);
}

 final  List<String> _partialLocations;
@override@JsonKey() List<String> get partialLocations {
  if (_partialLocations is EqualUnmodifiableListView) return _partialLocations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_partialLocations);
}

@override final  DateTime? oldestFetch;
@override final  DateTime? nextRefresh;
@override@JsonKey() final  bool isRefreshing;

/// Create a copy of NotamFetchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotamFetchResultCopyWith<_NotamFetchResult> get copyWith => __$NotamFetchResultCopyWithImpl<_NotamFetchResult>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotamFetchResult&&const DeepCollectionEquality().equals(other.notams, _notams)&&const DeepCollectionEquality().equals(other.failedLocations, _failedLocations)&&const DeepCollectionEquality().equals(other.partialLocations, _partialLocations)&&(identical(other.oldestFetch, oldestFetch) || other.oldestFetch == oldestFetch)&&(identical(other.nextRefresh, nextRefresh) || other.nextRefresh == nextRefresh)&&(identical(other.isRefreshing, isRefreshing) || other.isRefreshing == isRefreshing));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_notams),const DeepCollectionEquality().hash(_failedLocations),const DeepCollectionEquality().hash(_partialLocations),oldestFetch,nextRefresh,isRefreshing);
}

@override
String toString() {
    return 'NotamFetchResult(notams: $notams, failedLocations: $failedLocations, partialLocations: $partialLocations, oldestFetch: $oldestFetch, nextRefresh: $nextRefresh, isRefreshing: $isRefreshing)';
}


}

/// @nodoc
abstract mixin class _$NotamFetchResultCopyWith<$Res> implements $NotamFetchResultCopyWith<$Res> {
  factory _$NotamFetchResultCopyWith(_NotamFetchResult value, $Res Function(_NotamFetchResult) _then) = __$NotamFetchResultCopyWithImpl;
@override @useResult
$Res call({
 List<Notam> notams, List<String> failedLocations, List<String> partialLocations, DateTime? oldestFetch, DateTime? nextRefresh, bool isRefreshing
});




}
/// @nodoc
class __$NotamFetchResultCopyWithImpl<$Res>
    implements _$NotamFetchResultCopyWith<$Res> {
  __$NotamFetchResultCopyWithImpl(this._self, this._then);

  final _NotamFetchResult _self;
  final $Res Function(_NotamFetchResult) _then;

/// Create a copy of NotamFetchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? notams = null,Object? failedLocations = null,Object? partialLocations = null,Object? oldestFetch = freezed,Object? nextRefresh = freezed,Object? isRefreshing = null,}) {
  return _then(_NotamFetchResult(
null == notams ? _self._notams : notams // ignore: cast_nullable_to_non_nullable
as List<Notam>,failedLocations: null == failedLocations ? _self._failedLocations : failedLocations // ignore: cast_nullable_to_non_nullable
as List<String>,partialLocations: null == partialLocations ? _self._partialLocations : partialLocations // ignore: cast_nullable_to_non_nullable
as List<String>,oldestFetch: freezed == oldestFetch ? _self.oldestFetch : oldestFetch // ignore: cast_nullable_to_non_nullable
as DateTime?,nextRefresh: freezed == nextRefresh ? _self.nextRefresh : nextRefresh // ignore: cast_nullable_to_non_nullable
as DateTime?,isRefreshing: null == isRefreshing ? _self.isRefreshing : isRefreshing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
