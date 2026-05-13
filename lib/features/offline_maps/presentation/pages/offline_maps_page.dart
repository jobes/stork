import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre/maplibre.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/style_provider.dart';
import '../providers/offline_maps_provider.dart';
import '../../domain/offline_maps_state.dart';

class OfflineMapsPage extends ConsumerStatefulWidget {
  const OfflineMapsPage({super.key});

  @override
  ConsumerState<OfflineMapsPage> createState() => _OfflineMapsPageState();
}

class _OfflineMapsPageState extends ConsumerState<OfflineMapsPage> {
  final GlobalKey _mapKey = GlobalKey();
  MapController? _mapController;
  bool _isAdding = false;
  Geographic? _startPoint;
  Geographic? _currentEndPoint;
  String? _selectedRegionId;
  String? _resizingHandle; // 'nw', 'ne', 'sw', 'se'
  bool _isMoving = false;
  Geographic? _moveStartPoint;
  Geographic? _regionStartNw;
  Geographic? _regionStartSe;

  bool get _shouldDisableMapGestures =>
      (_isAdding && _startPoint != null) ||
      _resizingHandle != null ||
      _isMoving;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(offlineMapsProvider);
    final notifier = ref.read(offlineMapsProvider.notifier);

    ref.listen(offlineMapsProvider, (previous, next) {
      if (next.hasError && !(previous?.hasError ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.downloadError),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.offlineMaps)),
        body: const Center(
          child: Text('Offline maps are not supported on web.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.offlineMaps),
        actions: _buildAppBarActions(state, notifier, l10n),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMapSection(state, notifier, l10n)),
          _buildBottomPanel(state, notifier, l10n),
        ],
      ),
    );
  }

  List<Widget> _buildAppBarActions(
    OfflineMapsState state,
    OfflineMapsNotifier notifier,
    AppLocalizations l10n,
  ) {
    return [
      if (_selectedRegionId != null)
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: l10n.deleteArea,
          onPressed: () {
            notifier.removeRegion(_selectedRegionId!);
            setState(() => _selectedRegionId = null);
          },
        ),
      if (state.regions.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          tooltip: l10n.deleteAll,
          onPressed: () => _confirmDeleteAll(notifier, l10n),
        ),
      IconButton(
        icon: Icon(_isAdding ? Icons.close : Icons.add_box),
        tooltip: l10n.addArea,
        onPressed: () {
          setState(() {
            _isAdding = !_isAdding;
            _startPoint = null;
            _currentEndPoint = null;
          });
        },
      ),
    ];
  }

  Future<void> _confirmDeleteAll(
    OfflineMapsNotifier notifier,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteConfirmationTitle),
        content: Text(l10n.deleteConfirmationContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await notifier.clearAll();
      setState(() => _selectedRegionId = null);
    }
  }

  Widget _buildMapSection(
    OfflineMapsState state,
    OfflineMapsNotifier notifier,
    AppLocalizations l10n,
  ) {
    final styleAsync = ref.watch(mapStyleProvider);

    return Stack(
      key: _mapKey,
      children: [
        styleAsync.when(
          data: (style) => MapLibreMap(
            options: MapOptions(
              initCenter: Geographic(lon: 0, lat: 0),
              initZoom: 1,
              initStyle: style,
              minZoom: 1,
              maxZoom: 6,
              gestures: _shouldDisableMapGestures
                  ? const MapGestures.none()
                  : const MapGestures.all(rotate: false, pitch: false),
            ),
            onMapCreated: (controller) =>
                setState(() => _mapController = controller),
            onEvent: (event) {
              if (event is MapEventClick) {
                _handleMapClick(event.point);
              } else if (event is MapEventMoveCamera) {
                setState(() {});
              }
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text('${l10n.mapLoadingError}: $error')),
        ),
        if (_mapController != null) _buildOverlayLayer(state, notifier),
      ],
    );
  }

  Widget _buildOverlayLayer(
    OfflineMapsState state,
    OfflineMapsNotifier notifier,
  ) {
    final List<Widget> layers = [];

    // Background painter
    layers.add(
      IgnorePointer(
        child: CustomPaint(
          painter: RegionPainter(
            regions: state.regions,
            controller: _mapController!,
            selectedId: _selectedRegionId,
            startPoint: _startPoint,
            endPoint: _currentEndPoint,
            isAdding: _isAdding,
          ),
          size: Size.infinite,
        ),
      ),
    );

    // Interaction handlers
    if (_isAdding) {
      layers.add(_buildNewRegionGestureDetector(state, notifier));
    } else if (_selectedRegionId != null) {
      layers.addAll(_buildSelectedRegionControls(state, notifier));
    }

    return Stack(children: layers);
  }

  Widget _buildNewRegionGestureDetector(
    OfflineMapsState state,
    OfflineMapsNotifier notifier,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanDown: (details) => _handlePanStart(details.localPosition, state),
      onPanUpdate: (details) =>
          _handlePanUpdate(details.localPosition, state, notifier),
      onPanEnd: (_) => _handlePanEnd(notifier),
      child: const SizedBox.expand(),
    );
  }

  List<Widget> _buildSelectedRegionControls(
    OfflineMapsState state,
    OfflineMapsNotifier notifier,
  ) {
    try {
      final region = state.regions.firstWhere((r) => r.id == _selectedRegionId);
      final nw = _mapController!.toScreenLocation(region.northwest);
      final se = _mapController!.toScreenLocation(region.southeast);
      final ne = _mapController!.toScreenLocation(
        Geographic(lon: region.southeast.lon, lat: region.northwest.lat),
      );
      final sw = _mapController!.toScreenLocation(
        Geographic(lon: region.northwest.lon, lat: region.southeast.lat),
      );
      final rect = Rect.fromPoints(nw, se);

      return [
        _buildHandle(nw, 'nw', state, notifier),
        _buildHandle(ne, 'ne', state, notifier),
        _buildHandle(sw, 'sw', state, notifier),
        _buildHandle(se, 'se', state, notifier),
        Positioned.fromRect(
          rect: rect,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) => _handlePanStart(
              _getMapRelativeOffset(details.globalPosition),
              state,
            ),
            onPanUpdate: (details) => _handlePanUpdate(
              _getMapRelativeOffset(details.globalPosition),
              state,
              notifier,
            ),
            onPanEnd: (_) => _handlePanEnd(notifier),
            child: const SizedBox.expand(),
          ),
        ),
      ];
    } catch (_) {
      return [];
    }
  }

  Widget _buildHandle(
    Offset center,
    String handle,
    OfflineMapsState state,
    OfflineMapsNotifier notifier,
  ) {
    const handleSize = 40.0;
    return Positioned(
      left: center.dx - handleSize / 2,
      top: center.dy - handleSize / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (details) {
          setState(() => _resizingHandle = handle);
          _handlePanStart(_getMapRelativeOffset(details.globalPosition), state);
        },
        onPanUpdate: (details) => _handlePanUpdate(
          _getMapRelativeOffset(details.globalPosition),
          state,
          notifier,
        ),
        onPanEnd: (_) => _handlePanEnd(notifier),
        child: Container(
          width: handleSize,
          height: handleSize,
          color: Colors.transparent,
        ),
      ),
    );
  }

  Offset _getMapRelativeOffset(Offset globalPosition) {
    final box = _mapKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.globalToLocal(globalPosition) ?? globalPosition;
  }

  void _handleMapClick(Geographic point) {
    if (_isAdding) return;

    final state = ref.read(offlineMapsProvider);
    String? hitId;
    for (var region in state.regions.reversed) {
      if (_isInside(point, region)) {
        hitId = region.id;
        break;
      }
    }
    setState(() => _selectedRegionId = hitId);
  }

  void _handlePanStart(Offset position, OfflineMapsState state) {
    final geo = _mapController!.toLngLat(position);
    if (_isAdding) {
      setState(() {
        _startPoint = geo;
        _currentEndPoint = geo;
      });
      return;
    }

    if (_selectedRegionId != null && _resizingHandle == null) {
      final region = state.regions.firstWhere((r) => r.id == _selectedRegionId);
      final nw = _mapController!.toScreenLocation(region.northwest);
      final se = _mapController!.toScreenLocation(region.southeast);
      final ne = _mapController!.toScreenLocation(
        Geographic(lon: region.southeast.lon, lat: region.northwest.lat),
      );
      final sw = _mapController!.toScreenLocation(
        Geographic(lon: region.northwest.lon, lat: region.southeast.lat),
      );

      const hSize = 20.0;
      if ((position - nw).distance < hSize) {
        _resizingHandle = 'nw';
      } else if ((position - ne).distance < hSize) {
        _resizingHandle = 'ne';
      } else if ((position - sw).distance < hSize) {
        _resizingHandle = 'sw';
      } else if ((position - se).distance < hSize) {
        _resizingHandle = 'se';
      }

      if (_resizingHandle != null) {
        setState(() {});
        return;
      }
    }

    for (var region in state.regions.reversed) {
      if (_isInside(geo, region)) {
        setState(() {
          _selectedRegionId = region.id;
          _isMoving = true;
          _moveStartPoint = geo;
          _regionStartNw = region.northwest;
          _regionStartSe = region.southeast;
        });
        return;
      }
    }
    setState(() {});
  }

  void _handlePanUpdate(
    Offset position,
    OfflineMapsState state,
    OfflineMapsNotifier notifier,
  ) {
    if (_isAdding && _startPoint != null) {
      setState(() => _currentEndPoint = _mapController!.toLngLat(position));
      return;
    }

    if (_selectedRegionId != null) {
      final geo = _mapController!.toLngLat(position);
      final region = state.regions.firstWhere((r) => r.id == _selectedRegionId);

      if (_resizingHandle != null) {
        _performResize(geo, region, notifier);
      } else if (_isMoving) {
        _performMove(geo, notifier);
      }
    }
  }

  void _performResize(
    Geographic geo,
    OfflineMapArea region,
    OfflineMapsNotifier notifier,
  ) {
    Geographic nw = region.northwest;
    Geographic se = region.southeast;
    switch (_resizingHandle) {
      case 'nw':
        nw = geo;
        break;
      case 'se':
        se = geo;
        break;
      case 'ne':
        nw = Geographic(lon: nw.lon, lat: geo.lat);
        se = Geographic(lon: geo.lon, lat: se.lat);
        break;
      case 'sw':
        nw = Geographic(lon: geo.lon, lat: nw.lat);
        se = Geographic(lon: se.lon, lat: geo.lat);
        break;
    }
    notifier.updateRegion(_selectedRegionId!, nw: nw, se: se);
  }

  void _performMove(Geographic geo, OfflineMapsNotifier notifier) {
    final dLon = geo.lon - _moveStartPoint!.lon;
    final dLat = geo.lat - _moveStartPoint!.lat;
    notifier.updateRegion(
      _selectedRegionId!,
      nw: Geographic(
        lon: _regionStartNw!.lon + dLon,
        lat: _regionStartNw!.lat + dLat,
      ),
      se: Geographic(
        lon: _regionStartSe!.lon + dLon,
        lat: _regionStartSe!.lat + dLat,
      ),
    );
  }

  void _handlePanEnd(OfflineMapsNotifier notifier) {
    if (_isAdding && _startPoint != null && _currentEndPoint != null) {
      final distLon = (_currentEndPoint!.lon - _startPoint!.lon).abs();
      final distLat = (_currentEndPoint!.lat - _startPoint!.lat).abs();

      if (distLon > 0.001 || distLat > 0.001) {
        final newId = notifier.addRegion(_startPoint!, _currentEndPoint!);
        setState(() {
          _selectedRegionId = newId;
          _isAdding = false;
          _startPoint = null;
          _currentEndPoint = null;
        });
      }
    }
    setState(() {
      _resizingHandle = null;
      _isMoving = false;
    });
  }

  bool _isInside(Geographic point, OfflineMapArea region) {
    final minLat = min(region.northwest.lat, region.southeast.lat);
    final maxLat = max(region.northwest.lat, region.southeast.lat);
    final minLon = min(region.northwest.lon, region.southeast.lon);
    final maxLon = max(region.northwest.lon, region.southeast.lon);
    return point.lat >= minLat &&
        point.lat <= maxLat &&
        point.lon >= minLon &&
        point.lon <= maxLon;
  }

  Widget _buildBottomPanel(
    OfflineMapsState state,
    OfflineMapsNotifier notifier,
    AppLocalizations l10n,
  ) {
    return PointerInterceptor(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSummaryRow(state, l10n),
              _buildDownloadButton(state, notifier, l10n),
              if (state.regions.isEmpty)
                _buildEmptyStateText(l10n)
              else
                _buildProgressSection(state, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(OfflineMapsState state, AppLocalizations l10n) {
    if (state.downloadDate == null ||
        !state.isDownloaded ||
        state.downloadedTiles == 0) {
      return const SizedBox.shrink();
    }
    final date = DateFormat('dd.MM.yyyy HH:mm').format(state.downloadDate!);
    final detail = l10n.lastUpdateDetail(
      _formatBytes(state.downloadedBytes + state.metadataBytes),
      _formatBytes(state.worldBytes),
      _formatBytes(state.openAipBytes),
      _formatBytes(state.terrainBytes),
      _formatBytes(state.metadataBytes),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        '${l10n.lastUpdate(date)} $detail',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _buildDownloadButton(
    OfflineMapsState state,
    OfflineMapsNotifier notifier,
    AppLocalizations l10n,
  ) {
    if (state.isDownloading) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.stop),
          label: Text(l10n.cancelDownload),
          onPressed: () => notifier.cancelDownload(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(state.isDownloaded ? Icons.refresh : Icons.download),
        label: Text(l10n.downloadMaps),
        onPressed: state.regions.isEmpty
            ? null
            : () => notifier.startDownload(),
      ),
    );
  }

  Widget _buildEmptyStateText(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        l10n.noAreasSelected,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  Widget _buildProgressSection(OfflineMapsState state, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        children: [
          Text(
            l10n.areaCount(state.regions.length),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (state.isDownloading && !state.isDownloadingMetadata)
            _ProgressIndicator(
              value: state.totalTiles > 0
                  ? state.downloadedTiles / state.totalTiles
                  : 0,
              label: l10n.tileProgress(
                state.downloadedTiles,
                state.totalTiles,
                _formatBytes(state.downloadedBytes),
              ),
            )
          else if (state.isDownloadingMetadata)
            _ProgressIndicator(
              value: state.totalMetadataCountries > 0
                  ? state.downloadedMetadataCountries /
                        state.totalMetadataCountries
                  : 0,
              label: l10n.downloadingMetadata,
              trailing:
                  '${l10n.metadataProgress(state.downloadedMetadataCountries, state.totalMetadataCountries)} (${_formatBytes(state.metadataBytes)})',
              color: Colors.orange,
            ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _ProgressIndicator extends StatelessWidget {
  final double value;
  final String label;
  final String? trailing;
  final Color? color;

  const _ProgressIndicator({
    required this.value,
    required this.label,
    this.trailing,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey.withAlpha(50),
          borderRadius: BorderRadius.circular(4),
          color: color,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            if (trailing != null)
              Text(trailing!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

class RegionPainter extends CustomPainter {
  final List<OfflineMapArea> regions;
  final MapController controller;
  final String? selectedId;
  final Geographic? startPoint;
  final Geographic? endPoint;
  final bool isAdding;

  RegionPainter({
    required this.regions,
    required this.controller,
    this.selectedId,
    this.startPoint,
    this.endPoint,
    required this.isAdding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final blueFill = Paint()
      ..color = Colors.blue.withAlpha(77)
      ..style = PaintingStyle.fill;
    final blueStroke = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final orangeFill = Paint()
      ..color = Colors.orange.withAlpha(102)
      ..style = PaintingStyle.fill;
    final orangeStroke = Paint()
      ..color = Colors.orange
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final handleFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (var region in regions) {
      final rect = _getRect(region.northwest, region.southeast);
      final isSelected = region.id == selectedId;
      canvas.drawRect(rect, isSelected ? orangeFill : blueFill);
      canvas.drawRect(rect, isSelected ? orangeStroke : blueStroke);
      if (isSelected) _drawHandles(canvas, rect, handleFill, orangeStroke);
    }

    if (isAdding && startPoint != null && endPoint != null) {
      final rect = _getRect(startPoint!, endPoint!);
      canvas.drawRect(rect, blueFill);
      canvas.drawRect(rect, blueStroke);
    }
  }

  Rect _getRect(Geographic nw, Geographic se) {
    final nwOffset = controller.toScreenLocation(nw);
    final seOffset = controller.toScreenLocation(se);
    return Rect.fromPoints(nwOffset, seOffset);
  }

  void _drawHandles(Canvas canvas, Rect rect, Paint fill, Paint border) {
    const radius = 6.0;
    for (var p in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      canvas.drawCircle(p, radius, fill);
      canvas.drawCircle(p, radius, border);
    }
  }

  @override
  bool shouldRepaint(covariant RegionPainter oldDelegate) => true;
}
