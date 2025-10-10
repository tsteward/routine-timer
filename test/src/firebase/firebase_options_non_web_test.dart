import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/firebase/firebase_options_non_web.dart';

void main() {
  test('DefaultFirebaseOptions.web throws on non-web', () {
    expect(() => DefaultFirebaseOptions.web, throwsA(isA<UnsupportedError>()));
  });
}
