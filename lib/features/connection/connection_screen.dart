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
  final _tokenController = TextEditingController();
  bool _showTokenField = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    if (state.gatewayUrl != null) {
      _urlController.text = state.gatewayUrl!;
    }
    if (state.gatewayToken != null && state.gatewayToken!.isNotEmpty) {
      _tokenController.text = state.gatewayToken!;
      _showTokenField = true;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isLoading = true);

    final state = context.read<AppState>();
    final success = await state.connect(
      url,
      token: _tokenController.text.trim().isEmpty
          ? null
          : _tokenController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (!success && state.connectionError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.connectionError!),
            backgroundColor: HermesTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _autoConnect() async {
    final state = context.read<AppState>();
    if (state.gatewayUrl != null && state.gatewayUrl!.isNotEmpty) {
      setState(() => _isLoading = true);
      await state.connect(
        state.gatewayUrl!,
        token: state.gatewayToken,
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Auto-connect if credentials saved and not already connected
    if (state.gatewayUrl != null &&
        state.gatewayUrl!.isNotEmpty &&
        state.connectionState == GatewayConnectionState.idle &&
        !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoConnect());
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
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: HermesTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hermes',
                  style: TextStyle(
                    fontSize: 32,
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
                const SizedBox(height: 48),

                // Gateway URL field
                TextField(
                  controller: _urlController,
                  style: const TextStyle(color: HermesTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Gateway URL',
                    hintText: 'http://192.168.1.100:8080',
                    prefixIcon: Icon(Icons.link_rounded, color: HermesTheme.textMuted),
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 12),

                // Token toggle
                GestureDetector(
                  onTap: () => setState(() => _showTokenField = !_showTokenField),
                  child: Row(
                    children: [
                      Icon(
                        _showTokenField
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: HermesTheme.textMuted,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showTokenField ? 'Hide token' : 'Add auth token',
                        style: const TextStyle(
                          color: HermesTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showTokenField) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tokenController,
                    style: const TextStyle(color: HermesTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Auth Token',
                      hintText: 'Optional session token',
                      prefixIcon: Icon(Icons.key_rounded, color: HermesTheme.textMuted),
                    ),
                    obscureText: true,
                    enabled: !_isLoading,
                  ),
                ],
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