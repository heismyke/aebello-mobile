import 'package:flutter/foundation.dart';

/// Where the Go backend (svc) runs. Override per build:
///   flutter run --dart-define=API_URL=https://api.aebello.com
///
/// The Android emulator reaches the host computer at 10.0.2.2, so that is the
/// local default there; everything else uses localhost.
String get apiBaseUrl {
  const fromBuild = String.fromEnvironment('API_URL');
  if (fromBuild.isNotEmpty) return fromBuild;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://localhost:8080';
}
