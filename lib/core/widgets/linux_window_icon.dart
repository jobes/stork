import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Keeps the Linux window icon in sync with the effective application theme.
class LinuxWindowIcon extends StatefulWidget {
  const LinuxWindowIcon({super.key, required this.child});

  final Widget child;

  @override
  State<LinuxWindowIcon> createState() => _LinuxWindowIconState();
}

class _LinuxWindowIconState extends State<LinuxWindowIcon> {
  static const _channel = MethodChannel('com.inskycore.stork/window_icon');
  Brightness? _brightness;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.linux) return;
    final brightness = Theme.of(context).brightness;
    if (_brightness == brightness) return;
    _brightness = brightness;
    unawaited(_updateIcon(brightness));
  }

  Future<void> _updateIcon(Brightness brightness) async {
    try {
      await _channel.invokeMethod<void>(
        'setDarkIcon',
        brightness == Brightness.dark,
      );
    } on PlatformException catch (error) {
      debugPrint('Could not update Linux window icon: $error');
    } on MissingPluginException catch (error) {
      debugPrint('Could not update Linux window icon: $error');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
