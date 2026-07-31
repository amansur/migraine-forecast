import 'package:flutter/material.dart';

import '../../data/sources/open_meteo/open_meteo_geocoder.dart';

/// A reusable dialog that lets the user search for a location by name.
///
/// Extracted from `settings_screen.dart` so both the settings flow and the
/// day-detail sheet (historical location override) can share it.
///
/// Usage:
/// ```dart
/// showDialog<void>(
///   context: context,
///   builder: (_) => LocationSearchDialog(
///     geocoder: ref.read(geocoderProvider),
///     onPick: (result) { /* use result.lat / result.lon / result.displayName */ },
///   ),
/// );
/// ```
class LocationSearchDialog extends StatefulWidget {
  final OpenMeteoGeocoder geocoder;
  final void Function(GeocodingResult) onPick;

  /// Optional text to pre-fill the search field with (e.g. the currently-set
  /// location's name so the user can edit it).
  final String? initialQuery;

  /// When provided, the dialog shows an explicit option to switch back to the
  /// automatic (GPS / app-resolved) location. Without this there is no in-dialog
  /// path to the auto state — the user has to know about a separate button.
  final VoidCallback? onUseAuto;

  /// Whether the automatic location is the currently-active choice, so the
  /// Automatic/Manual toggle opens on the right segment.
  final bool isCurrentlyAuto;

  const LocationSearchDialog({
    super.key,
    required this.geocoder,
    required this.onPick,
    this.initialQuery,
    this.onUseAuto,
    this.isCurrentlyAuto = false,
  });

  @override
  State<LocationSearchDialog> createState() => _LocationSearchDialogState();
}

enum _LocationMode { auto, manual }

class _LocationSearchDialogState extends State<LocationSearchDialog> {
  final _ctrl = TextEditingController();
  List<GeocodingResult> _results = [];
  bool _loading = false;
  String? _error;
  late _LocationMode _mode;
  GeocodingResult? _selected;

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.initialQuery ?? '';
    _mode = widget.isCurrentlyAuto ? _LocationMode.auto : _LocationMode.manual;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.geocoder.search(q);
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Search failed: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set location'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onUseAuto != null) ...[
              SegmentedButton<_LocationMode>(
                key: const Key('location-mode-toggle'),
                segments: const [
                  ButtonSegment(
                    value: _LocationMode.auto,
                    label: Text('Automatic'),
                    icon: Icon(Icons.my_location),
                  ),
                  ButtonSegment(
                    value: _LocationMode.manual,
                    label: Text('Manual'),
                    icon: Icon(Icons.edit_location_alt),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) =>
                    setState(() => _mode = selection.first),
              ),
              const SizedBox(height: 12),
            ],
            // All search UI is Manual-only — in Automatic mode the search
            // field, results, and "no results" message are irrelevant.
            if (_mode == _LocationMode.manual) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        labelText: 'City, state, country or postal code',
                        hintText: 'e.g. city, ZIP, or country',
                      ),
                      onSubmitted: (_) => _search(),
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.search), onPressed: _search),
                ],
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              if (_results.isNotEmpty) ...[
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final r = _results[i];
                      final selected = identical(r, _selected);
                      return ListTile(
                        selected: selected,
                        title: Text(r.displayName),
                        subtitle: Text(
                            '${r.lat.toStringAsFixed(4)}, ${r.lon.toStringAsFixed(4)}'),
                        trailing: selected
                            ? Icon(Icons.check,
                                color: Theme.of(context).colorScheme.primary)
                            : null,
                        onTap: () => setState(() => _selected = r),
                      );
                    },
                  ),
                ),
              ] else if (!_loading &&
                  _ctrl.text.isNotEmpty &&
                  _results.isEmpty &&
                  _error == null)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text('No results — try a different search term'),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('location-ok'),
          onPressed: _canConfirm ? _confirm : null,
          child: const Text('OK'),
        ),
      ],
    );
  }

  /// OK is enabled when there's a committable choice: Automatic (when the caller
  /// supports it), or a picked search result in Manual mode.
  bool get _canConfirm =>
      (_mode == _LocationMode.auto && widget.onUseAuto != null) ||
      (_mode == _LocationMode.manual && _selected != null);

  void _confirm() {
    if (_mode == _LocationMode.auto) {
      widget.onUseAuto?.call();
    } else if (_selected != null) {
      widget.onPick(_selected!);
    }
    Navigator.pop(context);
  }
}
