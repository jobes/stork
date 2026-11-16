import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../data/services/map_search.dart';
import '../../../domain/models/map_search_result.dart';

Future<MapSearchResult?> showMapSearchDialog(
  BuildContext context, {
  required double latitude,
  required double longitude,
}) => showDialog<MapSearchResult>(
  context: context,
  builder: (_) => _MapSearchDialog(latitude: latitude, longitude: longitude),
);

class _MapSearchDialog extends ConsumerStatefulWidget {
  const _MapSearchDialog({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  ConsumerState<_MapSearchDialog> createState() => _MapSearchDialogState();
}

enum _MunicipalityStatus { idle, loading, empty, failed }

class _MapSearchDialogState extends ConsumerState<_MapSearchDialog> {
  final _field = TextEditingController();
  Timer? _debounce;
  int _queryVersion = 0;
  var _airports = <MapSearchResult>[];
  var _favorites = <MapSearchResult>[];
  var _municipalities = <MapSearchResult>[];
  var _municipalityStatus = _MunicipalityStatus.idle;
  bool _loadingLocal = false;
  bool _localFailed = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _field.dispose();
    super.dispose();
  }

  Future<void> _search(String input) async {
    final version = ++_queryVersion;
    bool isCurrent() => mounted && version == _queryVersion;

    _debounce?.cancel();
    final query = input.trim();
    final nameQuery = normalizeMapSearchText(query);
    setState(() {
      _airports = [];
      _favorites = [];
      _municipalities = [];
      _municipalityStatus = _MunicipalityStatus.idle;
      _loadingLocal = nameQuery.isNotEmpty;
      _localFailed = false;
    });
    if (nameQuery.isEmpty) return;

    var airports = <MapSearchResult>[];
    var favorites = <MapSearchResult>[];
    var localFailed = false;
    try {
      final airportRecords = ref.read(airportSearchRecordsProvider);
      if (airportRecords.hasError && !airportRecords.isLoading) {
        ref.invalidate(airportSearchRecordsProvider);
      }
      final records = await ref.read(airportSearchRecordsProvider.future);
      if (!isCurrent()) return;
      airports = searchAirportRecords(records, query);
    } catch (_) {
      localFailed = true;
    }
    if (!isCurrent()) return;

    final favoriteLimit = mapSearchLimit - airports.length;
    if (favoriteLimit > 0) {
      // Show airport matches even if the saved points are still loading.
      setState(() => _airports = airports);
      try {
        final points = await ref.read(favoritesProvider.future);
        if (!isCurrent()) return;
        favorites = points
            .where(
              (point) => normalizeMapSearchText(point.name).contains(nameQuery),
            )
            .take(favoriteLimit)
            .map(
              (point) => MapSearchResult(
                type: MapSearchResultType.favorite,
                name: point.name,
                latitude: point.latitude,
                longitude: point.longitude,
              ),
            )
            .toList();
      } catch (_) {
        localFailed = true;
      }
    }
    if (!isCurrent()) return;
    setState(() {
      _airports = airports;
      _favorites = favorites;
      _loadingLocal = false;
      _localFailed = localFailed;
    });

    final remaining = favoriteLimit - favorites.length;
    if (remaining > 0) {
      _debounce = Timer(const Duration(milliseconds: 350), () async {
        setState(() => _municipalityStatus = _MunicipalityStatus.loading);
        try {
          final municipalities = await ref
              .read(photonSearchProvider)
              .search(
                query,
                latitude: widget.latitude,
                longitude: widget.longitude,
                limit: remaining,
              );
          if (!isCurrent()) return;
          setState(() {
            _municipalities = municipalities;
            _municipalityStatus = municipalities.isEmpty
                ? _MunicipalityStatus.empty
                : _MunicipalityStatus.idle;
          });
        } catch (_) {
          if (!isCurrent()) return;
          setState(() => _municipalityStatus = _MunicipalityStatus.failed);
        }
      });
    }
  }

  Widget _status(String message, {bool loading = false}) => Semantics(
    liveRegion: true,
    child: ListTile(
      dense: true,
      leading: loading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      title: Text(message),
    ),
  );

  List<Widget> _resultGroup(String title, List<MapSearchResult> results) {
    if (results.isEmpty) return [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Text(title, style: Theme.of(context).textTheme.labelLarge),
      ),
      for (final result in results)
        ListTile(
          dense: true,
          leading: Icon(switch (result.type) {
            MapSearchResultType.airport => Icons.flight,
            MapSearchResultType.favorite => Icons.star,
            MapSearchResultType.municipality => Icons.place_outlined,
          }),
          title: result.icaoCode.isEmpty
              ? Text(result.name)
              : Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: result.icaoCode,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (result.name != result.icaoCode)
                        TextSpan(text: '  ${result.name}'),
                    ],
                  ),
                ),
          subtitle: result.area.isEmpty ? null : Text(result.area),
          onTap: () => Navigator.of(context).pop(result),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Start loading the local data on opening, before the user starts typing.
    ref.watch(airportSearchRecordsProvider);
    ref.watch(favoritesProvider);
    ref.watch(photonSearchProvider);
    final l10n = AppLocalizations.of(context)!;
    final results = [
      ..._resultGroup(l10n.mapSearchAirports, _airports),
      ..._resultGroup(l10n.favoritesTitle, _favorites),
      if (_loadingLocal) _status(l10n.mapSearchLoadingLocal, loading: true),
      if (_localFailed) _status(l10n.mapSearchLocalFailed),
      ..._resultGroup(l10n.mapSearchMunicipalities, _municipalities),
    ];
    final municipalityStatus = switch (_municipalityStatus) {
      _MunicipalityStatus.loading => _status(
        l10n.mapSearchLoadingMunicipalities,
        loading: true,
      ),
      _MunicipalityStatus.empty => _status(l10n.mapSearchNoMunicipalities),
      _MunicipalityStatus.failed => _status(l10n.mapSearchMunicipalitiesFailed),
      _MunicipalityStatus.idle => null,
    };

    return Dialog(
      alignment: Alignment.topLeft,
      insetPadding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxWidth: 480),
      child: PointerInterceptor(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      controller: _field,
                      onChanged: _search,
                      decoration: InputDecoration(
                        hintText: l10n.mapSearchHint,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_field.text.isNotEmpty)
                    IconButton(
                      tooltip: l10n.mapSearchClear,
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _field.clear();
                        unawaited(_search(''));
                      },
                    ),
                ],
              ),
            ),
            if (results.isNotEmpty)
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: results,
                ),
              ),
            ?municipalityStatus,
          ],
        ),
      ),
    );
  }
}
