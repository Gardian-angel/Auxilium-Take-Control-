// Native stand-in for `dart:js_interop`, used by the web-only services
// (web_auth_service.dart, location_service.dart) through a conditional import.
// Those services return early when !kIsWeb, so nothing here is ever called.

class JS {
  final String? name;
  const JS([this.name]);
}

class JSFunction {}

extension FunctionToJSExportedDartFunction on Function {
  JSFunction get toJS =>
      throw UnsupportedError('JS interop is only available on web');
}
