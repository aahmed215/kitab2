// Conditional import: selects native.dart or web.dart based on platform.
export 'native.dart' if (dart.library.js_interop) 'web.dart';
