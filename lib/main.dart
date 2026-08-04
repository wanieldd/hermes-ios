import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final appState = AppState();
  appState.init();

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const HermesApp(),
    ),
  );
}