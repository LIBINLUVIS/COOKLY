import 'package:flutter/material.dart';

import '../screens/splash/splash_screen.dart';
import '../services/session_store.dart';

/// Clears the persisted session and returns to the splash/sign-in flow.
/// Takes [context] from the caller at call time (not captured earlier),
/// since the widget that originally navigated to the home screen may
/// already be disposed by the time sign-out is actually tapped.
Future<void> signOutAndShowSplash(BuildContext context) async {
  await SessionStore.instance.clear();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const SplashScreen()),
    (route) => false,
  );
}
