import 'dart:async';
import 'package:flutter/foundation.dart';

// Web-only imports compiled away on non-web targets
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop' if (dart.library.io) 'package:inprov/core/services/_stub_js.dart';

// JS interop declarations (web only)
@JS('gisInitAndPrompt')
external void _gisInitAndPrompt(String clientId, JSFunction dartCallback);

@JS('gisRenderButton')
external void _gisRenderButton(
    String elementId, String clientId, JSFunction dartCallback);

@JS('gisCancelPrompt')
external void _gisCancelPrompt();

/// Signs in via Google Identity Services on Flutter Web.
///
/// Returns the raw JWT credential string, or null if sign-in is cancelled/unavailable.
Future<String?> signInWithGisWeb(String clientId) async {
  if (!kIsWeb) return null;
  final completer = Completer<String?>();
  _gisInitAndPrompt(
    clientId,
    (String? credential) {
      if (!completer.isCompleted) {
        completer.complete(credential);
      }
    }.toJS,
  );
  // Time out after 2 minutes to avoid leaking the completer.
  return completer.future.timeout(const Duration(minutes: 2), onTimeout: () {
    _gisCancelPrompt();
    return null;
  });
}

/// Renders the GIS sign-in button inside the DOM element with [elementId].
///
/// Returns the credential JWT, or null if the user cancels.
Future<String?> renderGisButtonWeb(String elementId, String clientId) async {
  if (!kIsWeb) return null;
  final completer = Completer<String?>();
  _gisRenderButton(
    elementId,
    clientId,
    (String? credential) {
      if (!completer.isCompleted) {
        completer.complete(credential);
      }
    }.toJS,
  );
  return completer.future;
}

/// Cancels a pending GIS prompt (web only, no-op elsewhere).
void cancelGisPrompt() {
  if (kIsWeb) _gisCancelPrompt();
}
