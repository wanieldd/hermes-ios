import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/models.dart';
import 'core/app_state.dart';
import 'features/chat/chat_screen.dart';
import 'features/connection/connection_screen.dart';
import 'features/connection/login_screen.dart';
import 'features/sessions/sessions_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/skills/skills_screen.dart';
import 'shared/theme/hermes_theme.dart';

class HermesApp extends StatelessWidget {
  const HermesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hermes',
      debugShowCheckedModeBanner: false,
      theme: HermesTheme.darkTheme,
      home: const _AppShell(),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _currentTab = 0;

  void _switchToChat() {
    setState(() => _currentTab = 0);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Not connected at all - no credentials saved
    if (state.connectionState == GatewayConnectionState.idle &&
        state.gatewayUrl == null) {
      return const ConnectionScreen();
    }

    // Has URL but needs auth - show login
    if (state.connectionState == GatewayConnectionState.idle ||
        state.connectionState == GatewayConnectionState.closed ||
        state.connectionState == GatewayConnectionState.error) {
      return const LoginScreen();
    }

    // Connected - show main app
    final screens = [
      const ChatScreen(),
      SessionsScreen(onSessionSelected: _switchToChat),
      const SkillsScreen(),
      const SettingsScreen(),
    ];

    const labels = ['Chat', 'Sessions', 'Skills', 'Settings'];
    const icons = [
      Icons.chat_rounded,
      Icons.forum_rounded,
      Icons.auto_awesome_rounded,
      Icons.settings_rounded,
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: HermesTheme.border, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (index) => setState(() => _currentTab = index),
          items: List.generate(4, (i) {
            return BottomNavigationBarItem(
              icon: Icon(icons[i]),
              activeIcon: Icon(icons[i]),
              label: labels[i],
            );
          }),
        ),
      ),
    );
  }
}