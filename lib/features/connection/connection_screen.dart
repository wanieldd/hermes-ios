import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/models.dart';
import '../../core/app_state.dart';
import '../../shared/theme/hermes_theme.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _urlController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    if (state.gatewayUrl != null) {
      _urlController.text = state.gatewayUrl!;
    }
    // Auto-connect if we have saved credentials
    if (state.gatewayUrl != null && state.gatewayUrl!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _connect());
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isLoading = true);

    final state = context.read<AppState>();
    await state.connect(url);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isConnected = state.connectionState == GatewayConnectionState.open;

    // If connected, return empty -- the parent shell will switch to main app
    if (isConnected) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: HermesTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hermes',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: HermesTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Connect to your agent',
                  style: TextStyle(
                    fontSize: 15,
                    color: HermesTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),

                // Gateway URL field
                TextField(
                  controller: _urlController,
                  style: const TextStyle(color: HermesTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Gateway URL',
                    hintText: 'http://192.168.1.100:9120',
                    prefixIcon: Icon(Icons.link_rounded, color: HermesTheme.textMuted),
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 24),

                // Connect button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _connect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HermesTheme.primary,
                      disabledBackgroundColor: HermesTheme.primary.withValues(alpha: 0.4),
                      foregroundColor: HermesTheme.textInverse,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Connect',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                // Connection error
                if (state.connectionError != null && !_isLoading) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: HermesTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: HermesTheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline,
                            color: HermesTheme.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.connectionError!,
                            style: const TextStyle(
                              color: HermesTheme.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Connecting state
                if (state.connectionState == GatewayConnectionState.connecting) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: HermesTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Connecting...',
                        style: TextStyle(
                          color: HermesTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}