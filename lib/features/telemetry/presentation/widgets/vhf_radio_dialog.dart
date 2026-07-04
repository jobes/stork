import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stork/core/services/database/database_service.dart';
import 'package:stork/features/map/presentation/providers/airport_metadata_provider.dart';
import 'package:stork/features/map/presentation/providers/airspace_metadata_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/vhf_radio_controller.dart';
import 'package:stork/core/utils/geo_utils.dart';
import 'package:stork/features/map/domain/airport_metadata.dart';
import 'package:stork/features/map/domain/airspace_metadata.dart';
import 'package:stork/features/telemetry/presentation/providers/favorite_frequencies_provider.dart';
import 'package:stork/features/telemetry/presentation/widgets/manage_favorites_dialog.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';

part 'vhf_radio_dialog_quick_ext.dart';
part 'vhf_radio_dialog_advanced_ext.dart';

part 'vhf_radio_dialog_lists_ext.dart';
part 'vhf_radio_dialog_audio_ext.dart';

class VhfRadioDialog extends ConsumerStatefulWidget {
  final int radioInstance;
  final int nodeId;
  final int initialActiveKhz;
  final int initialStandbyKhz;
  final String initialActiveName;
  final String initialStandbyName;
  final int initialVolume;
  final int initialSquelch;
  final int initialVox;
  final int initialIntercom;
  final List<int> initialMicGain;
  final bool initialIsDual;

  const VhfRadioDialog({
    super.key,
    required this.radioInstance,
    required this.nodeId,
    required this.initialActiveKhz,
    required this.initialStandbyKhz,
    required this.initialActiveName,
    required this.initialStandbyName,
    required this.initialVolume,
    required this.initialSquelch,
    required this.initialVox,
    required this.initialIntercom,
    required this.initialMicGain,
    required this.initialIsDual,
  });

  @override
  ConsumerState<VhfRadioDialog> createState() => _VhfRadioDialogState();
}

class _VhfRadioDialogState extends ConsumerState<VhfRadioDialog> {
  late final TextEditingController _activeController;
  late final TextEditingController _activeNameController;
  late final TextEditingController _standbyController;
  late final TextEditingController _standbyNameController;
  
  late double _volume;
  late double _squelch;
  late double _vox;
  late double _intercom;
  late List<double> _micGains;
  late bool _isDual;

  // Track currently saved values locally to determine dirty state
  late String _savedActiveText;
  late String _savedActiveName;
  late String _savedStandbyText;
  late String _savedStandbyName;
  
  late int _savedVolume;
  late int _savedSquelch;
  late int _savedVox;
  late int _savedIntercom;
  late List<int> _savedMicGains;

  bool _isSaving = false;
  String? _errorMessage;
  bool _showAudioControls = false;
  bool _showAdvancedMode = false;

  List<MapEntry<AirportMetadata, double>> _nearbyAirports = [];
  bool _loadingAirports = true;
  List<MapEntry<AirspaceMetadata, double>> _nearbyAirspaces = [];
  bool _loadingAirspaces = true;

  @override
  void initState() {
    super.initState();
    _activeController = TextEditingController(text: (widget.initialActiveKhz / 1000.0).toStringAsFixed(3));
    _activeNameController = TextEditingController(text: widget.initialActiveName);
    _standbyController = TextEditingController(text: (widget.initialStandbyKhz / 1000.0).toStringAsFixed(3));
    _standbyNameController = TextEditingController(text: widget.initialStandbyName);
    
    _volume = widget.initialVolume.toDouble();
    _squelch = widget.initialSquelch.toDouble();
    _vox = widget.initialVox.toDouble();
    _intercom = widget.initialIntercom.toDouble();
    _micGains = widget.initialMicGain.map((g) => g.toDouble()).toList();
    _isDual = widget.initialIsDual;

    _savedActiveText = (widget.initialActiveKhz / 1000.0).toStringAsFixed(3);
    _savedActiveName = widget.initialActiveName;
    _savedStandbyText = (widget.initialStandbyKhz / 1000.0).toStringAsFixed(3);
    _savedStandbyName = widget.initialStandbyName;

    _savedVolume = widget.initialVolume;
    _savedSquelch = widget.initialSquelch;
    _savedVox = widget.initialVox;
    _savedIntercom = widget.initialIntercom;
    _savedMicGains = List<int>.from(widget.initialMicGain);

    // Listen to changes on text controllers to update the green save checkmark state on keystrokes
    _activeController.addListener(() => setState(() {}));
    _activeNameController.addListener(() => setState(() {}));
    _standbyController.addListener(() => setState(() {}));
    _standbyNameController.addListener(() => setState(() {}));

    _loadNearbyAirports();
    _loadNearbyAirspaces();
  }

  Future<void> _loadNearbyAirports() async {
    final telemetry = ref.read(telemetryProvider);
    final lat = telemetry.latitude;
    final lon = telemetry.longitude;
    if (lat == null || lon == null) {
      if (mounted) {
        setState(() {
          _loadingAirports = false;
        });
      }
      return;
    }

    try {
      final memoryAirports = ref.read(airportMetadataCacheProvider.notifier).memoryCache.values.toList();
      
      final dbFeatures = await DatabaseService.getAllOpenAipFeatures('apt');
      final dbAirports = dbFeatures.map((json) {
        try {
          return AirportMetadata.fromJson(json);
        } catch (_) {
          return null;
        }
      }).whereType<AirportMetadata>().toList();

      final allAirportsMap = <String, AirportMetadata>{};
      for (final apt in dbAirports) {
        if (apt.latitude != null && apt.longitude != null) {
          allAirportsMap[apt.id] = apt;
        }
      }
      for (final apt in memoryAirports) {
        if (apt.latitude != null && apt.longitude != null) {
          allAirportsMap[apt.id] = apt;
        }
      }

      final listWithDistance = allAirportsMap.values.map((apt) {
        final dist = GeoUtils.distanceBetween(lat, lon, apt.latitude!, apt.longitude!);
        return MapEntry(apt, dist);
      }).toList();

      listWithDistance.sort((a, b) => a.value.compareTo(b.value));

      if (mounted) {
        setState(() {
          _nearbyAirports = listWithDistance.take(5).toList();
          _loadingAirports = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingAirports = false;
        });
      }
    }
  }

  Future<void> _loadNearbyAirspaces() async {
    final telemetry = ref.read(telemetryProvider);
    final lat = telemetry.latitude;
    final lon = telemetry.longitude;
    if (lat == null || lon == null) {
      if (mounted) {
        setState(() {
          _loadingAirspaces = false;
        });
      }
      return;
    }

    try {
      final memoryAirspaces = ref.read(airspaceMetadataCacheProvider.notifier).memoryCache.values.toList();
      
      final dbFeatures = await DatabaseService.getAllOpenAipFeatures('asp');
      final dbAirspaces = dbFeatures.map((json) {
        try {
          return AirspaceMetadata.fromJson(json);
        } catch (_) {
          return null;
        }
      }).whereType<AirspaceMetadata>().toList();

      final allAirspacesMap = <String, AirspaceMetadata>{};
      for (final asp in dbAirspaces) {
        if (asp.geometry != null) {
          allAirspacesMap[asp.id] = asp;
        }
      }
      for (final asp in memoryAirspaces) {
        if (asp.geometry != null) {
          allAirspacesMap[asp.id] = asp;
        }
      }



      final listWithDistance = allAirspacesMap.values.map((asp) {
        final dist = GeoUtils.distanceToPolygons(lat, lon, asp.polygons);
        return MapEntry(asp, dist);
      }).where((entry) => entry.key.frequencies != null && entry.key.frequencies!.isNotEmpty).toList();

      listWithDistance.sort((a, b) {
        final distA = a.value;
        final distB = b.value;
        if (distA == 0.0 && distB == 0.0) {
          return a.key.name.toLowerCase().compareTo(b.key.name.toLowerCase());
        }
        return distA.compareTo(distB);
      });

      if (mounted) {
        setState(() {
          _nearbyAirspaces = listWithDistance.take(5).toList();
          _loadingAirspaces = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingAirspaces = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _activeController.dispose();
    _activeNameController.dispose();
    _standbyController.dispose();
    _standbyNameController.dispose();
    super.dispose();
  }

  Future<void> _quickSetFrequency(double mhz, String name, bool isActive) async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final freqStr = mhz.toStringAsFixed(3);
    final freqKhz = _parseAviationFrequency(freqStr);
    if (freqKhz == null) {
      setState(() {
        _isSaving = false;
        _errorMessage = "Frekvencia $freqStr MHz nie je platná.";
      });
      return;
    }

    try {
      final controller = ref.read(vhfRadioControllerProvider.notifier);
      if (isActive) {
        await controller.setActiveFrequency(
          nodeId: widget.nodeId,
          radioInstance: widget.radioInstance,
          frequencyKhz: freqKhz,
          name: name,
        );
      } else {
        await controller.setStandbyFrequency(
          nodeId: widget.nodeId,
          radioInstance: widget.radioInstance,
          frequencyKhz: freqKhz,
          name: name,
        );
      }
      
      setState(() {
        if (isActive) {
          _activeController.text = freqStr;
          _activeNameController.text = name;
          _savedActiveText = freqStr;
          _savedActiveName = name;
        } else {
          _standbyController.text = freqStr;
          _standbyNameController.text = name;
          _savedStandbyText = freqStr;
          _savedStandbyName = name;
        }
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e is TimeoutException
            ? "DroneCAN neodpovedal (Timeout 1s)."
            : "Chyba rýchleho nastavenia frekvencie: ${e.toString()}";
      });
    }
  }

  int? _parseAviationFrequency(String text) {
    if (!RegExp(r'^\d{3}\.\d{3}$').hasMatch(text.trim())) return null;

    final double? mhz = double.tryParse(text.trim());
    if (mhz == null) return null;
    if (mhz < 118.000 || mhz > 136.995) return null;

    final int totalKzRounded = (mhz * 1000).round();
    final int offset = totalKzRounded % 100;

    const Set<int> validAviationOffsets = {
      0, 5, 10, 15, 25, 30, 35, 40, 50, 55, 60, 65, 75, 80, 85, 90,
    };

    if (!validAviationOffsets.contains(offset)) {
      return null;
    }

    return totalKzRounded;
  }

  Future<void> _flipFrequencies() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final controller = ref.read(vhfRadioControllerProvider.notifier);
      await controller.flipFrequencies(
        nodeId: widget.nodeId,
        radioInstance: widget.radioInstance,
      );
      
      final tempFreq = _activeController.text;
      _activeController.text = _standbyController.text;
      _standbyController.text = tempFreq;

      final tempName = _activeNameController.text;
      _activeNameController.text = _standbyNameController.text;
      _standbyNameController.text = tempName;

      // Swap the saved variables too so the checkmarks react correctly
      final tempSavedText = _savedActiveText;
      _savedActiveText = _savedStandbyText;
      _savedStandbyText = tempSavedText;

      final tempSavedName = _savedActiveName;
      _savedActiveName = _savedStandbyName;
      _savedStandbyName = tempSavedName;

      setState(() {
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e is TimeoutException 
            ? "DroneCAN neodpovedal na Flip (Timeout 1s)." 
            : "Chyba Flip: ${e.toString()}";
      });
    }
  }

  Future<void> _toggleDualWatch(bool val) async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final controller = ref.read(vhfRadioControllerProvider.notifier);
      await controller.toggleDualWatch(
        nodeId: widget.nodeId,
        radioInstance: widget.radioInstance,
      );

      setState(() {
        _isDual = val;
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e is TimeoutException
            ? "DroneCAN neodpovedal na Dual Watch (Timeout 1s)."
            : "Chyba Dual Watch: ${e.toString()}";
      });
    }
  }

  Future<void> _saveActive() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final activeKhz = _parseAviationFrequency(_activeController.text);
    if (activeKhz == null) {
      setState(() {
        _isSaving = false;
        _errorMessage = "Aktívna frekvencia musí byť platná letecká frekvencia (118.000 - 136.975 MHz).";
      });
      return;
    }

    try {
      final controller = ref.read(vhfRadioControllerProvider.notifier);
      await controller.setActiveFrequency(
        nodeId: widget.nodeId,
        radioInstance: widget.radioInstance,
        frequencyKhz: activeKhz,
        name: _activeNameController.text,
      );
      setState(() {
        _savedActiveText = _activeController.text.trim();
        _savedActiveName = _activeNameController.text;
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e is TimeoutException 
            ? "DroneCAN neodpovedal na aktívnu frekvenciu (Timeout 1s)." 
            : "Chyba uloženia aktívnej frekvencie: ${e.toString()}";
      });
    }
  }

  Future<void> _saveStandby() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final standbyKhz = _parseAviationFrequency(_standbyController.text);
    if (standbyKhz == null) {
      setState(() {
        _isSaving = false;
        _errorMessage = "Standby frekvencia musí byť platná letecká frekvencia (118.000 - 136.975 MHz).";
      });
      return;
    }

    try {
      final controller = ref.read(vhfRadioControllerProvider.notifier);
      await controller.setStandbyFrequency(
        nodeId: widget.nodeId,
        radioInstance: widget.radioInstance,
        frequencyKhz: standbyKhz,
        name: _standbyNameController.text,
      );
      setState(() {
        _savedStandbyText = _standbyController.text.trim();
        _savedStandbyName = _standbyNameController.text;
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e is TimeoutException 
            ? "DroneCAN neodpovedal na standby frekvenciu (Timeout 1s)." 
            : "Chyba uloženia standby frekvencie: ${e.toString()}";
      });
    }
  }

  Future<void> _saveVolume() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final targetVol = _volume.round();
    try {
      final controller = ref.read(vhfRadioControllerProvider.notifier);
      await controller.setVolume(
        widget.nodeId,
        widget.radioInstance,
        targetVol,
      );
      setState(() {
        _savedVolume = targetVol;
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e is TimeoutException 
            ? "DroneCAN neodpovedal na zmenu hlasitosti (Timeout 1s)." 
            : "Chyba uloženia hlasitosti: ${e.toString()}";
      });
    }
  }

  Future<void> _saveSquelch() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final targetSquelch = _squelch.round();
    try {
      final controller = ref.read(vhfRadioControllerProvider.notifier);
      await controller.setSquelch(
        widget.nodeId,
        widget.radioInstance,
        targetSquelch,
      );
      setState(() {
        _savedSquelch = targetSquelch;
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e is TimeoutException 
            ? "DroneCAN neodpovedal na squelch (Timeout 1s)." 
            : "Chyba uloženia squelch: ${e.toString()}";
      });
    }
  }

  Future<void> _saveVox() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final targetVox = _vox.round();
    try {
      final controller = ref.read(vhfRadioControllerProvider.notifier);
      await controller.setVox(
        widget.nodeId,
        widget.radioInstance,
        targetVox,
      );
      setState(() {
        _savedVox = targetVox;
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e is TimeoutException 
            ? "DroneCAN neodpovedal na VOX (Timeout 1s)." 
            : "Chyba uloženia VOX: ${e.toString()}";
      });
    }
  }

  Future<void> _saveIntercom() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final targetIntercom = _intercom.round();
    try {
      final controller = ref.read(vhfRadioControllerProvider.notifier);
      await controller.setIntercom(
        widget.nodeId,
        widget.radioInstance,
        targetIntercom,
      );
      setState(() {
        _savedIntercom = targetIntercom;
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e is TimeoutException 
            ? "DroneCAN neodpovedal na intercom (Timeout 1s)." 
            : "Chyba uloženia intercomu: ${e.toString()}";
      });
    }
  }

  Future<void> _saveMicGain(int index) async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final targetGain = _micGains[index].round();
    try {
      final controller = ref.read(vhfRadioControllerProvider.notifier);
      await controller.setMicGain(
        widget.nodeId,
        widget.radioInstance,
        index,
        targetGain,
      );
      setState(() {
        _savedMicGains[index] = targetGain;
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e is TimeoutException 
            ? "DroneCAN neodpovedal na mic gain (Timeout 1s)." 
            : "Chyba uloženia mic gain: ${e.toString()}";
      });
    }
  }



  void _showFrequencyMenu(Offset globalPosition, double mhz, String name) {
    final activeText = _activeController.text.trim();
    final standbyText = _standbyController.text.trim();
    final freqStr = mhz.toStringAsFixed(3);

    final isAlreadyActive = (activeText == freqStr);
    final isAlreadyStandby = (standbyText == freqStr);

    if (isAlreadyActive && isAlreadyStandby) {
      return; // Already active and standby on this radio
    }

    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        globalPosition,
        globalPosition,
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        if (!isAlreadyActive)
          const PopupMenuItem<String>(
            value: 'active',
            child: ListTile(
              leading: Icon(Icons.radio, color: Colors.green),
              title: Text('Nastaviť ako AKTÍVNU'),
              dense: true,
            ),
          ),
        if (!isAlreadyStandby)
          const PopupMenuItem<String>(
            value: 'standby',
            child: ListTile(
              leading: Icon(Icons.settings_input_antenna, color: Colors.blue),
              title: Text('Nastaviť ako STANDBY'),
              dense: true,
            ),
          ),
      ],
    ).then((String? value) {
      if (value == null) return;
      if (!context.mounted) return;
      _quickSetFrequency(mhz, name, value == 'active');
    });
  }




  @override
  Widget build(BuildContext context) {
    if (!_showAdvancedMode) {
      return _buildQuickContent(context);
    }
    return _buildAdvancedContent(context);
  }
}
class _FrequencyInfo {
  final double mhz;
  final String name;
  const _FrequencyInfo(this.mhz, this.name);
}
