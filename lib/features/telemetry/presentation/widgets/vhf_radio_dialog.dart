import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stork/core/services/cannelloni_service_io.dart';
import 'package:stork/core/native/dronecan/vhf_radio_control.dart';
import 'package:stork/core/services/database/database_service.dart';
import 'package:stork/features/map/presentation/providers/airport_metadata_provider.dart';
import 'package:stork/features/map/presentation/providers/airspace_metadata_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/core/utils/geo_utils.dart';
import 'package:stork/features/map/domain/airport_metadata.dart';
import 'package:stork/features/map/domain/airspace_metadata.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';

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
      final cannelloni = ref.read(cannelloniServiceProvider.notifier);
      final req = VhfRadioControlRequest(
        radioInstance: widget.radioInstance,
        action: isActive
            ? VhfRadioControlRequest.actionSetActiveFreq
            : VhfRadioControlRequest.actionSetStandbyFreq,
        frequencyKhz: freqKhz,
        frequencyName: name,
      );
      final res = await cannelloni.sendRequest(
        destinationNodeId: widget.nodeId,
        dataTypeId: VhfRadioControlRequest.messageId,
        dataTypeSignature: VhfRadioControlRequest.messageSignature,
        payload: req.toPayload(),
      );
      final response = VhfRadioControlResponse.fromPayload(res);
      if (response.status != VhfRadioControlResponse.statusOk) {
        throw Exception("Chyba pri rýchlom nastavení frekvencie");
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
      final cannelloni = ref.read(cannelloniServiceProvider.notifier);
      final req = VhfRadioControlRequest(
        radioInstance: widget.radioInstance,
        action: VhfRadioControlRequest.actionFlip,
      );
      final res = await cannelloni.sendRequest(
        destinationNodeId: widget.nodeId,
        dataTypeId: VhfRadioControlRequest.messageId,
        dataTypeSignature: VhfRadioControlRequest.messageSignature,
        payload: req.toPayload(),
      );
      final response = VhfRadioControlResponse.fromPayload(res);
      if (response.status != VhfRadioControlResponse.statusOk) {
        throw Exception("Chyba pri swapovaní frekvencií");
      }
      
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
      final cannelloni = ref.read(cannelloniServiceProvider.notifier);
      final req = VhfRadioControlRequest(
        radioInstance: widget.radioInstance,
        action: VhfRadioControlRequest.actionDualToggle,
      );
      final res = await cannelloni.sendRequest(
        destinationNodeId: widget.nodeId,
        dataTypeId: VhfRadioControlRequest.messageId,
        dataTypeSignature: VhfRadioControlRequest.messageSignature,
        payload: req.toPayload(),
      );
      final response = VhfRadioControlResponse.fromPayload(res);
      if (response.status != VhfRadioControlResponse.statusOk) {
        throw Exception("Chyba pri prepínaní dual watch");
      }

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
      final cannelloni = ref.read(cannelloniServiceProvider.notifier);
      final req = VhfRadioControlRequest(
        radioInstance: widget.radioInstance,
        action: VhfRadioControlRequest.actionSetActiveFreq,
        frequencyKhz: activeKhz,
        frequencyName: _activeNameController.text,
      );
      final res = await cannelloni.sendRequest(
        destinationNodeId: widget.nodeId,
        dataTypeId: VhfRadioControlRequest.messageId,
        dataTypeSignature: VhfRadioControlRequest.messageSignature,
        payload: req.toPayload(),
      );
      final response = VhfRadioControlResponse.fromPayload(res);
      if (response.status != VhfRadioControlResponse.statusOk) {
        throw Exception("Chyba pri nastavovaní aktívnej frekvencie");
      }
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
      final cannelloni = ref.read(cannelloniServiceProvider.notifier);
      final req = VhfRadioControlRequest(
        radioInstance: widget.radioInstance,
        action: VhfRadioControlRequest.actionSetStandbyFreq,
        frequencyKhz: standbyKhz,
        frequencyName: _standbyNameController.text,
      );
      final res = await cannelloni.sendRequest(
        destinationNodeId: widget.nodeId,
        dataTypeId: VhfRadioControlRequest.messageId,
        dataTypeSignature: VhfRadioControlRequest.messageSignature,
        payload: req.toPayload(),
      );
      final response = VhfRadioControlResponse.fromPayload(res);
      if (response.status != VhfRadioControlResponse.statusOk) {
        throw Exception("Chyba pri nastavovaní standby frekvencie");
      }
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
      final cannelloni = ref.read(cannelloniServiceProvider.notifier);
      final req = VhfRadioControlRequest(
        radioInstance: widget.radioInstance,
        action: VhfRadioControlRequest.actionSetVolume,
        level: targetVol,
      );
      final res = await cannelloni.sendRequest(
        destinationNodeId: widget.nodeId,
        dataTypeId: VhfRadioControlRequest.messageId,
        dataTypeSignature: VhfRadioControlRequest.messageSignature,
        payload: req.toPayload(),
      );
      final response = VhfRadioControlResponse.fromPayload(res);
      if (response.status != VhfRadioControlResponse.statusOk) {
        throw Exception("Chyba pri nastavovaní hlasitosti");
      }
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
      final cannelloni = ref.read(cannelloniServiceProvider.notifier);
      final req = VhfRadioControlRequest(
        radioInstance: widget.radioInstance,
        action: VhfRadioControlRequest.actionSetSquelch,
        level: targetSquelch,
      );
      final res = await cannelloni.sendRequest(
        destinationNodeId: widget.nodeId,
        dataTypeId: VhfRadioControlRequest.messageId,
        dataTypeSignature: VhfRadioControlRequest.messageSignature,
        payload: req.toPayload(),
      );
      final response = VhfRadioControlResponse.fromPayload(res);
      if (response.status != VhfRadioControlResponse.statusOk) {
        throw Exception("Chyba pri nastavovaní squelch");
      }
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
      final cannelloni = ref.read(cannelloniServiceProvider.notifier);
      final req = VhfRadioControlRequest(
        radioInstance: widget.radioInstance,
        action: VhfRadioControlRequest.actionSetVox,
        level: targetVox,
      );
      final res = await cannelloni.sendRequest(
        destinationNodeId: widget.nodeId,
        dataTypeId: VhfRadioControlRequest.messageId,
        dataTypeSignature: VhfRadioControlRequest.messageSignature,
        payload: req.toPayload(),
      );
      final response = VhfRadioControlResponse.fromPayload(res);
      if (response.status != VhfRadioControlResponse.statusOk) {
        throw Exception("Chyba pri nastavovaní VOX");
      }
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
      final cannelloni = ref.read(cannelloniServiceProvider.notifier);
      final req = VhfRadioControlRequest(
        radioInstance: widget.radioInstance,
        action: VhfRadioControlRequest.actionSetIntercom,
        level: targetIntercom,
      );
      final res = await cannelloni.sendRequest(
        destinationNodeId: widget.nodeId,
        dataTypeId: VhfRadioControlRequest.messageId,
        dataTypeSignature: VhfRadioControlRequest.messageSignature,
        payload: req.toPayload(),
      );
      final response = VhfRadioControlResponse.fromPayload(res);
      if (response.status != VhfRadioControlResponse.statusOk) {
        throw Exception("Chyba pri nastavovaní intercomu");
      }
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
      final cannelloni = ref.read(cannelloniServiceProvider.notifier);
      final req = VhfRadioControlRequest(
        radioInstance: widget.radioInstance,
        action: VhfRadioControlRequest.actionSetMicGain,
        level: targetGain,
        index: index,
      );
      final res = await cannelloni.sendRequest(
        destinationNodeId: widget.nodeId,
        dataTypeId: VhfRadioControlRequest.messageId,
        dataTypeSignature: VhfRadioControlRequest.messageSignature,
        payload: req.toPayload(),
      );
      final response = VhfRadioControlResponse.fromPayload(res);
      if (response.status != VhfRadioControlResponse.statusOk) {
        throw Exception("Chyba pri nastavovaní mic gain");
      }
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

  Widget _buildLabeledSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required VoidCallback onSave,
    required bool isSaveEnabled,
    IconData icon = Icons.volume_up,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            Text("${value.round()}%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        Row(
          children: [
            Icon(icon, size: 18),
            Expanded(
              child: Slider(
                value: value,
                min: 0,
                max: 100,
                divisions: 100,
                onChanged: _isSaving ? null : onChanged,
              ),
            ),
            IconButton(
              icon: Icon(Icons.check_circle_outline, color: isSaveEnabled ? Colors.green : Colors.grey.shade400),
              onPressed: (_isSaving || !isSaveEnabled) ? null : onSave,
              tooltip: "Uložiť zmenu",
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
          letterSpacing: 1.0,
        ),
      ),
    );
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

  Widget _buildAirportItem(String airportName, List<_FrequencyInfo> freqs) {
    if (freqs.length == 1) {
      final f = freqs.first;
      final cleanName = f.name.contains(" ")
          ? f.name.substring(f.name.indexOf(" ") + 1)
          : f.name;
      return _buildSimpleFrequencyRow("$airportName ($cleanName)", f.mhz, f.name);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              child: Text(
                airportName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 4),
            ...freqs.map((f) => _buildFrequencyRow(f.name, f.mhz)),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleFrequencyRow(String label, double mhz, String radioName) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTapUp: (details) => _showFrequencyMenu(details.globalPosition, mhz, radioName),
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      "${mhz.toStringAsFixed(3)} MHz",
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencyRow(String label, double mhz, {String? nameOverride}) {
    final freqStr = mhz.toStringAsFixed(3);
    final radioName = nameOverride ?? label;
    return InkWell(
      onTapUp: (details) => _showFrequencyMenu(details.globalPosition, mhz, radioName),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "$freqStr MHz",
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic dirty state calculation for Active Frequency / Name
    final activeText = _activeController.text.trim();
    final isActiveChanged = (activeText != _savedActiveText || _activeNameController.text != _savedActiveName) &&
        RegExp(r'^\d{3}\.\d{3}$').hasMatch(activeText) &&
        _parseAviationFrequency(activeText) != null;

    // Dynamic dirty state calculation for Standby Frequency / Name
    final standbyText = _standbyController.text.trim();
    final isStandbyChanged = (standbyText != _savedStandbyText || _standbyNameController.text != _savedStandbyName) &&
        RegExp(r'^\d{3}\.\d{3}$').hasMatch(standbyText) &&
        _parseAviationFrequency(standbyText) != null;

    if (!_showAdvancedMode) {
      return BaseDetailsDialog(
        titleText: "Radio COM${widget.radioInstance + 1}",
        icon: Icons.radio,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              key: const ValueKey('vhf_dialog_quick_content'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade400, width: 0.5),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Header showing Active & Standby
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        // Active
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "AKTÍVNA",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade600,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _activeController.text.isEmpty ? "---.---" : "${_activeController.text} MHz",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Text(
                                _activeNameController.text.isEmpty ? "Bez názvu" : _activeNameController.text,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Swap
                        IconButton(
                          icon: const Icon(Icons.swap_horiz, size: 28, color: Colors.blueAccent),
                          onPressed: _isSaving ? null : _flipFrequencies,
                          tooltip: "Prehodiť frekvencie",
                        ),
                        // Standby
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "STANDBY",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade600,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _standbyController.text.isEmpty ? "---.---" : "${_standbyController.text} MHz",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Text(
                                _standbyNameController.text.isEmpty ? "Bez názvu" : _standbyNameController.text,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Advanced Mode Button & Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Frekvencie v okolí",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => _showAdvancedMode = true),
                        icon: const Icon(Icons.tune, size: 16),
                        label: const Text("Pokročilé / Ručne", style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  _buildSectionHeader("Letiská v okolí"),
                  if (_loadingAirports)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (_nearbyAirports.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        "Žiadne letiská v okolí",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ..._nearbyAirports.map((entry) {
                      final apt = entry.key;
                      final distance = entry.value;
                      final distanceStr = (distance / 1000.0).toStringAsFixed(1);
                      final displayLabel = apt.icaoCode != null && apt.icaoCode!.isNotEmpty
                          ? "${apt.icaoCode} ${apt.name} ($distanceStr km)"
                          : "${apt.name} ($distanceStr km)";
                          
                      final freqs = apt.frequencies.map((f) {
                        final val = double.tryParse(f.value) ?? 0.0;
                        return _FrequencyInfo(val, f.name.isNotEmpty ? f.name : f.type.name);
                      }).where((f) => f.mhz > 0.0).toList();

                      return _buildAirportItem(displayLabel, freqs);
                    }),
                  const Divider(height: 16),
                  _buildSectionHeader("Obľúbené"),
                  _buildSimpleFrequencyRow("Emergency (Guard)", 121.500, "EMERGENCY"),
                  _buildSimpleFrequencyRow("LZTT Info (Poprad)", 134.915, "LZTT INFO"),
                  const Divider(height: 16),
                  _buildSectionHeader("Priestory"),
                  if (_loadingAirspaces)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (_nearbyAirspaces.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        "Žiadne priestory v okolí",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ..._nearbyAirspaces.map((entry) {
                      final asp = entry.key;
                      final distance = entry.value;
                      final distanceStr = distance == 0.0 ? "v priestore" : "${(distance / 1000.0).toStringAsFixed(1)} km";
                      final displayLabel = "${asp.name} ($distanceStr)";
                      
                      final freqs = asp.frequencies!.map((f) {
                        final val = double.tryParse(f.value) ?? 0.0;
                        return _FrequencyInfo(val, asp.name);
                      }).where((f) => f.mhz > 0.0).toList();

                      return _buildAirportItem(displayLabel, freqs);
                    }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            if (_isSaving)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return BaseDetailsDialog(
      titleText: "Radio COM${widget.radioInstance + 1}",
      icon: Icons.radio,
      actions: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _showAdvancedMode = false),
          tooltip: "Späť na zoznam",
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            key: const ValueKey('vhf_dialog_content'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade400, width: 0.5),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active Frequency block
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _activeController,
                            enabled: !_isSaving,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: "Aktívna Frekvencia (MHz)",
                              hintText: "118.000",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _activeNameController,
                            enabled: !_isSaving,
                            decoration: const InputDecoration(
                              labelText: "Meno aktívnej stanice",
                              hintText: "COM1 ACT",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: (_isSaving || !isActiveChanged) ? null : _saveActive,
                            icon: const Icon(Icons.check, size: 14),
                            label: const Text("Použiť", style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: BorderSide(color: isActiveChanged ? Colors.green : Colors.grey.shade400),
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Flip/Swap button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 24.0),
                      child: IconButton(
                        icon: const Icon(Icons.swap_horiz, size: 28, color: Colors.blueAccent),
                        onPressed: _isSaving ? null : _flipFrequencies,
                        tooltip: "Prehodiť frekvencie",
                      ),
                    ),

                    // Standby Frequency block
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _standbyController,
                            enabled: !_isSaving,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: "Standby Frekvencia (MHz)",
                              hintText: "121.500",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _standbyNameController,
                            enabled: !_isSaving,
                            decoration: const InputDecoration(
                              labelText: "Meno standby stanice",
                              hintText: "COM1 STB",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: (_isSaving || !isStandbyChanged) ? null : _saveStandby,
                            icon: const Icon(Icons.check, size: 14),
                            label: const Text("Použiť", style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: BorderSide(color: isStandbyChanged ? Colors.green : Colors.grey.shade400),
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Divider(height: 24),

                // Dual Watch Switch (Immediate Updates)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Dual Watch", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  value: _isDual,
                  onChanged: _isSaving ? null : _toggleDualWatch,
                ),

                const Divider(height: 24),

                // Audio Control Sliders with save buttons (collapsible)
                InkWell(
                  onTap: () => setState(() => _showAudioControls = !_showAudioControls),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    child: Row(
                      children: [
                        Icon(
                          _showAudioControls ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.blueAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _showAudioControls ? "Skryť nastavenia hlasitosti" : "Zobraziť nastavenia hlasitosti",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showAudioControls) ...[
                  const SizedBox(height: 12),
                  _buildLabeledSlider(
                    label: "Hlasitosť",
                    value: _volume,
                    onChanged: (val) => setState(() => _volume = val),
                    onSave: _saveVolume,
                    isSaveEnabled: _volume.round() != _savedVolume,
                    icon: Icons.volume_up,
                  ),
                  _buildLabeledSlider(
                    label: "Squelch (Šumová brána)",
                    value: _squelch,
                    onChanged: (val) => setState(() => _squelch = val),
                    onSave: _saveSquelch,
                    isSaveEnabled: _squelch.round() != _savedSquelch,
                    icon: Icons.filter_list,
                  ),
                  _buildLabeledSlider(
                    label: "VOX Citlivosť",
                    value: _vox,
                    onChanged: (val) => setState(() => _vox = val),
                    onSave: _saveVox,
                    isSaveEnabled: _vox.round() != _savedVox,
                    icon: Icons.keyboard_voice,
                  ),
                  _buildLabeledSlider(
                    label: "Intercom Hlasitosť",
                    value: _intercom,
                    onChanged: (val) => setState(() => _intercom = val),
                    onSave: _saveIntercom,
                    isSaveEnabled: _intercom.round() != _savedIntercom,
                    icon: Icons.people,
                  ),

                  // Microphones Gain Section with save buttons
                  if (_micGains.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text("Mikrofóny (Gain)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    ...List.generate(_micGains.length, (idx) {
                      final isGainChanged = _micGains[idx].round() != (idx < _savedMicGains.length ? _savedMicGains[idx] : 0);
                      return _buildLabeledSlider(
                        label: "Mikrofón ${idx + 1}",
                        value: _micGains[idx],
                        onChanged: (val) => setState(() => _micGains[idx] = val),
                        onSave: () => _saveMicGain(idx),
                        isSaveEnabled: isGainChanged,
                        icon: Icons.mic,
                      );
                    }),
                  ],
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),
          if (_isSaving)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FrequencyInfo {
  final double mhz;
  final String name;
  const _FrequencyInfo(this.mhz, this.name);
}
