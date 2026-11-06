import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

/// A firmware image selected by the user.
@immutable
class PickedFirmwareFile {
  const PickedFirmwareFile({required this.name, required this.bytes});

  /// File name including the extension, e.g. `AP_Periph.bin`.
  final String name;

  final Uint8List bytes;

  int get size => bytes.length;
}

/// Lets the user choose a firmware image from the local file system.
abstract interface class FirmwareFilePicker {
  /// Returns the selected image, or `null` when the user cancelled.
  Future<PickedFirmwareFile?> pick();
}

/// Opens the platform file dialog, restricted to DroneCAN firmware images.
class FileSelectorFirmwareFilePicker implements FirmwareFilePicker {
  const FileSelectorFirmwareFilePicker();

  @override
  Future<PickedFirmwareFile?> pick() async {
    const typeGroup = XTypeGroup(
      label: 'Firmware',
      extensions: ['bin'],
      mimeTypes: ['application/octet-stream'],
      uniformTypeIdentifiers: ['public.data'],
    );

    final file = await openFile(acceptedTypeGroups: const [typeGroup]);
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return PickedFirmwareFile(name: file.name, bytes: bytes);
  }
}
