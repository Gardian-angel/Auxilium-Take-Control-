import 'dart:async';
import 'package:flutter/foundation.dart';

// Web-only JS interop
import 'dart:js_interop' if (dart.library.io) 'package:inprov/core/services/_stub_js.dart';

@JS('getWebLocation')
external void _getWebLocation(JSFunction dartCallback);

class LocationResult {
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? error;

  const LocationResult({this.latitude, this.longitude, this.accuracy, this.error});

  bool get isSuccess => error == null && latitude != null && longitude != null;

  @override
  String toString() => isSuccess
      ? 'LocationResult(lat=$latitude, lng=$longitude, acc=${accuracy}m)'
      : 'LocationResult(error=$error)';
}

/// Requests the current device location.
///
/// On web, delegates to `navigator.geolocation.getCurrentPosition` via the JS
/// bridge in `web/index.html` (enableHighAccuracy: true).
/// On native platforms, returns an error — use `geolocator` package instead.
Future<LocationResult> getCurrentLocation() async {
  if (!kIsWeb) {
    return const LocationResult(
      error: 'Use geolocator package for native platforms',
    );
  }

  final completer = Completer<LocationResult>();

  _getWebLocation(
    (double? lat, double? lng, double? accuracy, String? error) {
      if (!completer.isCompleted) {
        if (error != null) {
          completer.complete(LocationResult(error: error));
        } else {
          completer.complete(LocationResult(
            latitude: lat,
            longitude: lng,
            accuracy: accuracy,
          ));
        }
      }
    }.toJS,
  );

  return completer.future.timeout(
    const Duration(seconds: 15),
    onTimeout: () => const LocationResult(error: 'Location request timed out'),
  );
}
