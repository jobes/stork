import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

/// Whether `RawDatagramSocket.bind` honours `reusePort` (`SO_REUSEPORT`) on
/// this platform.
///
/// The Dart VM implements it only on Linux and Apple platforms. On Android and
/// Windows the flag is ignored and the VM logs
/// "Dart Socket ERROR: ... `reusePort` not supported on this platform" for
/// every bind that requests it, so it must not be requested there.
bool get reusePortSupported =>
    !kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isIOS);
