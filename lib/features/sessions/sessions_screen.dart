import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/models.dart';
import '../../core/app_state.dart';
import '../../shared/theme/hermes_theme.dart';

class SessionsScreen extends StatefulWidget {
  final VoidCallback? onSessionSelected;

  const SessionsScreen({super.key, this.onSessionSelected});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  List<SessionInfo> _filteredSessions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      state.loadSessions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final state = context.read<AppState>();
    setState(() {
      _isSearching = query.isNotEmpty;
      if (_isSearching) {
        _filteredSessions = state.sessions
            .where((s) =>
                (s.title?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                (s.model?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList();
      } else {
        _filteredSessions = [];
      }
    });
  }

  Future<void> _refresh() async {
    await context.read<AppState>().loadSessions();
  }

  Future<void> _deleteSession(SessionInfo session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text('Delete "${session.title ?? 'Untitled'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: HermesTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<AppState>().deleteSession(session.id);
    }
  }

  Future<void> _renameSession(SessionInfo session) async {
    final controller = TextEditingController(text: session.title ?? '');
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Session'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Session title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    if (newTitle != null && newTitle.isNotEmpty) {
      await context.read<AppState>().renameSession(session.id, newTitle);
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sessions = _isSearching ? _filteredSessions : state.sessions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: const TextStyle(color: HermesTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search sessions...',
                hintStyle: const TextStyle(color: HermesTheme.textMuted),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: HermesTheme.textMuted, size: 20),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: HermesTheme.textMuted, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: HermesTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // Session list
          Expanded(
            child: state.isLoadingSessions
                ? const Center(child: CircularProgressIndicator())
                : sessions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.forum_outlined,
                              size: 48,
                              color: HermesTheme.textMuted.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No sessions yet',
                              style: TextStyle(
                                color: HermesTheme.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: sessions.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: HermesTheme.border,
                          ),
                          itemBuilder: (context, index) {
                            final session = sessions[index];
                            return _SessionTile(
                              session: session,
                              isActive: state.activeSession?.id == session.id,
                              onTap: () {
                                state.selectSession(session.id, session: session);
                                widget.onSessionSelected?.call();
                              },
                              onDelete: () => _deleteSession(session),
                              onRename: () => _renameSession(session),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final SessionInfo session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _SessionTile({
    required this.session,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final timeAgo = _timeAgo(session.updatedAt);

    return Dismissible(
      key: ValueKey(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: HermesTheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? HermesTheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              // Active indicator
              if (isActive)
                Container(
                  width: 3,
                  height: 24,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: HermesTheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

              // Icon
              Icon(
                session.source == 'discord' || session.source == 'telegram'
                    ? Icons.forum_rounded
                    : Icons.chat_rounded,
                color: isActive ? HermesTheme.primary : HermesTheme.textMuted,
                size: 20,
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title ?? 'Untitled',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isActive
                            ? HermesTheme.textPrimary
                            : HermesTheme.textSecondary,
                        fontSize: 15,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (session.model != null) ...[
                          Text(
                            session.model!,
                            style: const TextStyle(
                              color: HermesTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: HermesTheme.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          '${session.messageCount} msg',
                          style: const TextStyle(
                            color: HermesTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          timeAgo,
                          style: const TextStyle(
                            color: HermesTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // More button
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded,
                    color: HermesTheme.textMuted, size: 18),
                onSelected: (value) {
                  if (value == 'rename') onRename();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Rename'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: HermesTheme.error),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: HermesTheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('MMM d').format(date);
  }
}