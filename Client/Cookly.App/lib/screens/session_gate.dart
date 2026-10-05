import 'package:flutter/material.dart';

import '../models/cookly_session.dart';
import '../services/session_store.dart';
import '../theme/cookly_colors.dart';
import '../widgets/cookly_logo.dart';
import 'home/home_screen.dart';
import 'splash/splash_screen.dart';

/// The app's actual root: checks for a still-valid persisted session before
/// deciding what to show. A valid session skips straight to [HomeScreen];
/// otherwise it falls through to the normal [SplashScreen] -> sign-in flow.
class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late Future<CooklySession?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = SessionStore.instance.read();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CooklySession?>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SessionCheckingScreen();
        }

        final session = snapshot.data;
        if (session != null) {
          return HomeScreen(session: session);
        }

        return const SplashScreen();
      },
    );
  }
}

class _SessionCheckingScreen extends StatelessWidget {
  const _SessionCheckingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: CooklyColors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CooklyLogo(size: 64),
            SizedBox(height: 24),
            CircularProgressIndicator(color: CooklyColors.primary),
          ],
        ),
      ),
    );
  }
}
