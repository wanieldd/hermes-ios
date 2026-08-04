import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/models.dart';
import 'core/app_state.dart';
import 'features/chat/chat_screen.dart';
import 'features/connection/connection_screen.dart';
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
  bool _wasEverConnected = false;

  void _switchToChat() {
    setState(() => _currentTab = 0);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isOpen = state.connectionState == GatewayConnectionState.open;

    // Track if we've ever been connected
    if (isOpen && !_wasEverConnected) {
      _wasEverConnected = true;
    }

    // Never connected before - show connection screen
    if (!_wasEverConnected) {
      return const ConnectionScreen();
    }

    // Was connected before - show the main app with a banner when disconnected
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
      body: Column(
        children: [
          // Reconnecting banner
          if (!isOpen)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: HermesTheme.warning.withValues(alpha: 0.15),
              child: Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: HermesTheme.warning,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    state.connectionState == GatewayConnectionState.connecting
                        ? 'Reconnecting...'
                        : 'Disconnected -- tap here to reconnect',
                    style: const TextStyle(
                      color: HermesTheme.warning,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  if (state.connectionState != GatewayConnectionState.connecting)
                    GestureDetector(
                      onTap: () {
                        if (state.gatewayUrl != null) {
                          state.connect(state.gatewayUrl!);
                        }
                      },
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: HermesTheme.warning,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),

          // Main content
          Expanded(
            child: IndexedStack(
              index: _currentTab,
              children: screens,
            ),
          ),
        ],
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