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

  const LocationSearchDialog({
    super.key,
    required this.geocoder,
    required this.onPick,
  });

  @override
  State<LocationSearchDialog> createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends State<LocationSearchDialog> {
  final _ctrl = TextEditingController();
  List<GeocodingResult> _results = [];
  bool _loading = false;
  String? _error;

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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      labelText: 'City, state, country or postal code',
                      hintText: 'San Francisco, CA',
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
                    return ListTile(
                      title: Text(r.displayName),
                      subtitle: Text(
                          '${r.lat.toStringAsFixed(4)}, ${r.lon.toStringAsFixed(4)}'),
                      onTap: () {
                        widget.onPick(r);
                        Navigator.pop(context);
                      },
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
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
