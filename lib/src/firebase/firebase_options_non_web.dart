// Non-web stub to avoid requiring web secrets during Android/iOS builds
// This class mirrors the API surface used by web-only configuration so that
// non-web platforms do not need `lib/firebase_options.dart` present at build time.

class DefaultFirebaseOptions {
  static Never get web => throw UnsupportedError(
    'DefaultFirebaseOptions.web is only available on web builds.',
  );
}
