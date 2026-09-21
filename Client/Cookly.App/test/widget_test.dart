import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cookly_app/app.dart';

/// Uses an iPhone-13-sized portrait surface so layout assertions reflect a
/// real phone viewport rather than flutter_test's default 800x600 window.
Future<void> _setPhoneSurfaceSize(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// SessionGate reads flutter_secure_storage on startup, which has no
/// platform implementation under `flutter test` — stub it to resolve
/// immediately with "nothing stored" instead of relying on
/// MissingPluginException timing.
void _stubEmptySecureStorage(WidgetTester tester) {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
    (call) async => call.method == 'readAll' ? <String, String>{} : null,
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    ),
  );
}

void main() {
  testWidgets('Splash screen shows the entry CTA', (
    WidgetTester tester,
  ) async {
    await _setPhoneSurfaceSize(tester);
    _stubEmptySecureStorage(tester);
    await tester.pumpWidget(const CooklyApp());
    // SessionGate's storage read resolves over a real async gap (mocked
    // platform channel), and its own loading screen spins indefinitely, so
    // step through discrete frames rather than pumpAndSettle here.
    await tester.pump();
    await tester.pump();

    expect(find.text('Cookly'), findsOneWidget);
    expect(find.text('Tap to Enter Kitchen'), findsOneWidget);
  });

  testWidgets('Tapping the CTA navigates to the sign-in screen', (
    WidgetTester tester,
  ) async {
    await _setPhoneSurfaceSize(tester);
    _stubEmptySecureStorage(tester);
    await tester.pumpWidget(const CooklyApp());
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Tap to Enter Kitchen'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Cookly'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
