import 'dart:io';

/// Points at the local ASP.NET Core dev server (Cookly.Api), currently run
/// with the `http` launch profile only (port 5087) — UseHttpsRedirection
/// skips redirecting when it can't determine an HTTPS port to redirect to,
/// so plain HTTP works as long as only the http profile is running. Switch
/// back to `https` + port 7011 (see git history) if the `https` profile is
/// used instead.
class ApiConfig {
  ApiConfig._();

  static const int _devHttpPort = 5087;

  /// The Android emulator can't reach the host machine via `localhost`;
  /// `10.0.2.2` is its alias for the host loopback interface. iOS
  /// simulators share the host's network namespace, so `localhost` works
  /// there directly. A physical device needs the host's LAN IP instead.
  static String get baseUrl {
    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:$_devHttpPort';
  }
}
