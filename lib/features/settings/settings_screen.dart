import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/models.dart';
import '../../core/app_state.dart';
import '../../shared/theme/hermes_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // Connection section
          _SectionHeader(title: 'Connection'),
          _SettingsTile(
            icon: Icons.link_rounded,
            title: 'Gateway URL',
            subtitle: state.gatewayUrl ?? 'Not set',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.key_rounded,
            title: 'Auth Token',
            subtitle: state.gatewayToken != null && state.gatewayToken!.isNotEmpty
                ? '${state.gatewayToken!.substring(0, 8)}...'
                : 'None',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.wifi_rounded,
            title: 'Status',
            subtitle: state.connectionState == GatewayConnectionState.open
                ? 'Connected'
                : state.connectionState == GatewayConnectionState.connecting
                    ? 'Connecting...'
                    : 'Disconnected',
            trailing: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: state.connectionState == GatewayConnectionState.open
                    ? HermesTheme.success
                    : state.connectionState == GatewayConnectionState.connecting
                        ? HermesTheme.warning
                        : HermesTheme.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(color: HermesTheme.border, height: 1),
          _SettingsTile(
            icon: Icons.power_settings_new_rounded,
            title: 'Disconnect',
            subtitle: 'Close the gateway connection',
            iconColor: HermesTheme.warning,
            onTap: () => state.disconnect(),
          ),
          _SettingsTile(
            icon: Icons.delete_sweep_rounded,
            title: 'Clear Credentials',
            subtitle: 'Remove saved gateway URL and token',
            iconColor: HermesTheme.error,
            onTap: () => state.clearCredentials(),
          ),

          const SizedBox(height: 16),

          // Model section
          _SectionHeader(title: 'Model'),
          _SettingsTile(
            icon: Icons.psychology_rounded,
            title: 'Current Model',
            subtitle: state.modelInfo?.currentModel ?? 'Unknown',
            onTap: () => _showModelPicker(context, state),
          ),
          if (state.modelInfo?.currentProvider != null)
            _SettingsTile(
              icon: Icons.cloud_rounded,
              title: 'Provider',
              subtitle: state.modelInfo!.currentProvider!,
              onTap: null,
            ),

          const SizedBox(height: 16),

          // Server section
          _SectionHeader(title: 'Server'),
          if (state.status != null) ...[
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'Version',
              subtitle: state.status!.version,
              onTap: null,
            ),
            _SettingsTile(
              icon: Icons.circle_rounded,
              title: 'State',
              subtitle: state.status!.state,
              trailing: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: state.status!.state == 'running'
                      ? HermesTheme.success
                      : HermesTheme.warning,
                  shape: BoxShape.circle,
                ),
              ),
              onTap: null,
            ),
          ],
          _SettingsTile(
            icon: Icons.memory_rounded,
            title: 'Memory',
            subtitle: state.memoryStatus?.provider ?? 'Unknown',
            onTap: null,
          ),

          const SizedBox(height: 16),

          // About section
          _SectionHeader(title: 'About'),
          _SettingsTile(
            icon: Icons.bolt_rounded,
            title: 'Hermes iOS',
            subtitle: 'Version 1.0.0',
            onTap: null,
          ),
          _SettingsTile(
            icon: Icons.code_rounded,
            title: 'Built with Flutter',
            subtitle: 'Native iOS client for Hermes Agent',
            onTap: null,
          ),
        ],
      ),
    );
  }

  void _showModelPicker(BuildContext context, AppState state) {
    if (state.modelInfo?.availableModels == null ||
        state.modelInfo!.availableModels!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No models available')),
      );
      return;
    }

    // Group models by provider
    final modelsByProvider = <String, List<ModelInfo>>{};
    for (final model in state.modelInfo!.availableModels!) {
      modelsByProvider.putIfAbsent(model.provider, () => []).add(model);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: HermesTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                // Handle
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: HermesTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Select Model',
                    style: TextStyle(
                      color: HermesTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(color: HermesTheme.border, height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: modelsByProvider.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                color: HermesTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          ...entry.value.map((model) {
                            final isActive =
                                model.id == state.modelInfo?.currentModel;
                            return ListTile(
                              leading: Icon(
                                isActive
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                                color: isActive
                                    ? HermesTheme.primary
                                    : HermesTheme.textMuted,
                                size: 20,
                              ),
                              title: Text(
                                model.displayName ?? model.id,
                                style: TextStyle(
                                  color: isActive
                                      ? HermesTheme.textPrimary
                                      : HermesTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                model.id,
                                style: const TextStyle(
                                  color: HermesTheme.textMuted,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              onTap: () {
                                state.setModel(entry.key, model.id);
                                Navigator.pop(ctx);
                              },
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: HermesTheme.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? HermesTheme.textMuted, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          color: HermesTheme.textPrimary,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: HermesTheme.textMuted,
          fontSize: 13,
        ),
      ),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded,
                  color: HermesTheme.textMuted, size: 20)
              : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}