import 'dart:io';

/// Trusts the ASP.NET Core HTTPS dev-certificate for the local backend
/// during `flutter run`/debug builds only, so the app can hit
/// `https://localhost:7011` (or `10.0.2.2` on the Android emulator)
/// without installing that cert on the simulator/emulator. Only applied
/// from main() when `kDebugMode` is true, and only trusts those specific
/// dev hosts — every other host still goes through normal certificate
/// validation.
class DevHttpOverrides extends HttpOverrides {
  static const _trustedDevHosts = {'localhost', '127.0.0.1', '10.0.2.2'};

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (cert, host, port) =>
        _trustedDevHosts.contains(host);
    return client;
  }
}
