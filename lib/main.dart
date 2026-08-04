import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final appState = AppState();
  // Initialize storage and try to load saved credentials
  appState.init().catchError((e) {
    // Storage init failed, app still works without saved credentials
    debugPrint('Storage init failed (non-fatal): $e');
  });

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const HermesApp(),
    ),
  );
}