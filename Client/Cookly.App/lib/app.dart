import 'package:flutter/material.dart';

import 'screens/session_gate.dart';
import 'theme/cookly_theme.dart';

class CooklyApp extends StatelessWidget {
  const CooklyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cookly',
      debugShowCheckedModeBanner: false,
      theme: CooklyTheme.light,
      home: const SessionGate(),
    );
  }
}
