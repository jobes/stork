// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dronecan_firmware_update_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DroneCanFirmwareUpdateState implements DiagnosticableTreeMixin {

/// Image selected by the user, or `null` before a file was chosen.
 PickedFirmwareFile? get file; FirmwareUpdateProgress get progress;/// `true` while the platform file dialog is open.
 bool get isPicking;/// `true` once the upload stream closed after serving the whole image.
///
/// The stream stays open after [FirmwareUpdatePhase.completed] because the
/// node may still retry its last reads (or probe for the end of the file),
/// so the dialog must not close before this flag is set.
 bool get uploadFinished;/// Failure of the file dialog or of reading the image.
 Object? get pickError;
/// Create a copy of DroneCanFirmwareUpdateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DroneCanFirmwareUpdateStateCopyWith<DroneCanFirmwareUpdateState> get copyWith => _$DroneCanFirmwareUpdateStateCopyWithImpl<DroneCanFirmwareUpdateState>(this as DroneCanFirmwareUpdateState, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as DroneCanFirmwareUpdateState;
  properties
    ..add(DiagnosticsProperty('type', 'DroneCanFirmwareUpdateState'))
    ..add(DiagnosticsProperty('file', _this.file))..add(DiagnosticsProperty('progress', _this.progress))..add(DiagnosticsProperty('isPicking', _this.isPicking))..add(DiagnosticsProperty('uploadFinished', _this.uploadFinished))..add(DiagnosticsProperty('pickError', _this.pickError));
}

@override
bool operator ==(Object other) {
  final _this = this as DroneCanFirmwareUpdateState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DroneCanFirmwareUpdateState&&(identical(other.file, _this.file) || other.file == _this.file)&&(identical(other.progress, _this.progress) || other.progress == _this.progress)&&(identical(other.isPicking, _this.isPicking) || other.isPicking == _this.isPicking)&&(identical(other.uploadFinished, _this.uploadFinished) || other.uploadFinished == _this.uploadFinished)&&const DeepCollectionEquality().equals(other.pickError, _this.pickError));
}


@override
int get hashCode {
  final _this = this as DroneCanFirmwareUpdateState;
  return Object.hash(runtimeType,_this.file,_this.progress,_this.isPicking,_this.uploadFinished,const DeepCollectionEquality().hash(_this.pickError));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as DroneCanFirmwareUpdateState;
  return 'DroneCanFirmwareUpdateState(file: ${_this.file}, progress: ${_this.progress}, isPicking: ${_this.isPicking}, uploadFinished: ${_this.uploadFinished}, pickError: ${_this.pickError})';
}


}

/// @nodoc
abstract mixin class $DroneCanFirmwareUpdateStateCopyWith<$Res>  {
  factory $DroneCanFirmwareUpdateStateCopyWith(DroneCanFirmwareUpdateState value, $Res Function(DroneCanFirmwareUpdateState) _then) = _$DroneCanFirmwareUpdateStateCopyWithImpl;
@useResult
$Res call({
 PickedFirmwareFile? file, FirmwareUpdateProgress progress, bool isPicking, bool uploadFinished, Object? pickError
});


$FirmwareUpdateProgressCopyWith<$Res> get progress;

}
/// @nodoc
class _$DroneCanFirmwareUpdateStateCopyWithImpl<$Res>
    implements $DroneCanFirmwareUpdateStateCopyWith<$Res> {
  _$DroneCanFirmwareUpdateStateCopyWithImpl(this._self, this._then);

  final DroneCanFirmwareUpdateState _self;
  final $Res Function(DroneCanFirmwareUpdateState) _then;

/// Create a copy of DroneCanFirmwareUpdateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? file = freezed,Object? progress = null,Object? isPicking = null,Object? uploadFinished = null,Object? pickError = freezed,}) {
  return _then(DroneCanFirmwareUpdateState(
file: freezed == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as PickedFirmwareFile?,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as FirmwareUpdateProgress,isPicking: null == isPicking ? _self.isPicking : isPicking // ignore: cast_nullable_to_non_nullable
as bool,uploadFinished: null == uploadFinished ? _self.uploadFinished : uploadFinished // ignore: cast_nullable_to_non_nullable
as bool,pickError: freezed == pickError ? _self.pickError : pickError ,
  ));
}
/// Create a copy of DroneCanFirmwareUpdateState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FirmwareUpdateProgressCopyWith<$Res> get progress {
  
  return $FirmwareUpdateProgressCopyWith<$Res>(_self.progress, (value) {
    return _then(_self.copyWith(progress: value));
  });
}
}


/// Adds pattern-matching-related methods to [DroneCanFirmwareUpdateState].
extension DroneCanFirmwareUpdateStatePatterns on DroneCanFirmwareUpdateState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DroneCanFirmwareUpdateState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DroneCanFirmwareUpdateState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DroneCanFirmwareUpdateState value)  $default,){
final _that = this;
switch (_that) {
case _DroneCanFirmwareUpdateState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DroneCanFirmwareUpdateState value)?  $default,){
final _that = this;
switch (_that) {
case _DroneCanFirmwareUpdateState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PickedFirmwareFile? file,  FirmwareUpdateProgress progress,  bool isPicking,  bool uploadFinished,  Object? pickError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DroneCanFirmwareUpdateState() when $default != null:
return $default(_that.file,_that.progress,_that.isPicking,_that.uploadFinished,_that.pickError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PickedFirmwareFile? file,  FirmwareUpdateProgress progress,  bool isPicking,  bool uploadFinished,  Object? pickError)  $default,) {final _that = this;
switch (_that) {
case _DroneCanFirmwareUpdateState():
return $default(_that.file,_that.progress,_that.isPicking,_that.uploadFinished,_that.pickError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PickedFirmwareFile? file,  FirmwareUpdateProgress progress,  bool isPicking,  bool uploadFinished,  Object? pickError)?  $default,) {final _that = this;
switch (_that) {
case _DroneCanFirmwareUpdateState() when $default != null:
return $default(_that.file,_that.progress,_that.isPicking,_that.uploadFinished,_that.pickError);case _:
  return null;

}
}

}

/// @nodoc


class _DroneCanFirmwareUpdateState extends DroneCanFirmwareUpdateState with DiagnosticableTreeMixin {
  const _DroneCanFirmwareUpdateState({this.file, this.progress = FirmwareUpdateProgress.idle, this.isPicking = false, this.uploadFinished = false, this.pickError}): super._();
  

/// Image selected by the user, or `null` before a file was chosen.
@override final  PickedFirmwareFile? file;
@override@JsonKey() final  FirmwareUpdateProgress progress;
/// `true` while the platform file dialog is open.
@override@JsonKey() final  bool isPicking;
/// `true` once the upload stream closed after serving the whole image.
///
/// The stream stays open after [FirmwareUpdatePhase.completed] because the
/// node may still retry its last reads (or probe for the end of the file),
/// so the dialog must not close before this flag is set.
@override@JsonKey() final  bool uploadFinished;
/// Failure of the file dialog or of reading the image.
@override final  Object? pickError;

/// Create a copy of DroneCanFirmwareUpdateState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DroneCanFirmwareUpdateStateCopyWith<_DroneCanFirmwareUpdateState> get copyWith => __$DroneCanFirmwareUpdateStateCopyWithImpl<_DroneCanFirmwareUpdateState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'DroneCanFirmwareUpdateState'))
    ..add(DiagnosticsProperty('file', file))..add(DiagnosticsProperty('progress', progress))..add(DiagnosticsProperty('isPicking', isPicking))..add(DiagnosticsProperty('uploadFinished', uploadFinished))..add(DiagnosticsProperty('pickError', pickError));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DroneCanFirmwareUpdateState&&(identical(other.file, file) || other.file == file)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.isPicking, isPicking) || other.isPicking == isPicking)&&(identical(other.uploadFinished, uploadFinished) || other.uploadFinished == uploadFinished)&&const DeepCollectionEquality().equals(other.pickError, pickError));
}


@override
int get hashCode {
    return Object.hash(runtimeType,file,progress,isPicking,uploadFinished,const DeepCollectionEquality().hash(pickError));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'DroneCanFirmwareUpdateState(file: $file, progress: $progress, isPicking: $isPicking, uploadFinished: $uploadFinished, pickError: $pickError)';
}


}

/// @nodoc
abstract mixin class _$DroneCanFirmwareUpdateStateCopyWith<$Res> implements $DroneCanFirmwareUpdateStateCopyWith<$Res> {
  factory _$DroneCanFirmwareUpdateStateCopyWith(_DroneCanFirmwareUpdateState value, $Res Function(_DroneCanFirmwareUpdateState) _then) = __$DroneCanFirmwareUpdateStateCopyWithImpl;
@override @useResult
$Res call({
 PickedFirmwareFile? file, FirmwareUpdateProgress progress, bool isPicking, bool uploadFinished, Object? pickError
});


@override $FirmwareUpdateProgressCopyWith<$Res> get progress;

}
/// @nodoc
class __$DroneCanFirmwareUpdateStateCopyWithImpl<$Res>
    implements _$DroneCanFirmwareUpdateStateCopyWith<$Res> {
  __$DroneCanFirmwareUpdateStateCopyWithImpl(this._self, this._then);

  final _DroneCanFirmwareUpdateState _self;
  final $Res Function(_DroneCanFirmwareUpdateState) _then;

/// Create a copy of DroneCanFirmwareUpdateState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? file = freezed,Object? progress = null,Object? isPicking = null,Object? uploadFinished = null,Object? pickError = freezed,}) {
  return _then(_DroneCanFirmwareUpdateState(
file: freezed == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as PickedFirmwareFile?,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as FirmwareUpdateProgress,isPicking: null == isPicking ? _self.isPicking : isPicking // ignore: cast_nullable_to_non_nullable
as bool,uploadFinished: null == uploadFinished ? _self.uploadFinished : uploadFinished // ignore: cast_nullable_to_non_nullable
as bool,pickError: freezed == pickError ? _self.pickError : pickError ,
  ));
}

/// Create a copy of DroneCanFirmwareUpdateState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FirmwareUpdateProgressCopyWith<$Res> get progress {
  
  return $FirmwareUpdateProgressCopyWith<$Res>(_self.progress, (value) {
    return _then(_self.copyWith(progress: value));
  });
}
}

// dart format on
