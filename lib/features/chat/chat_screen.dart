import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/models.dart';
import '../../core/app_state.dart';
import '../../shared/theme/hermes_theme.dart';
import '../../shared/widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() => _isComposing = _textController.text.trim().isNotEmpty);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() => _isComposing = false);

    final state = context.read<AppState>();
    await state.sendPrompt(text);

    // Scroll to bottom after a short delay to let the streaming start
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  Future<void> _stopStreaming() async {
    // The desktop app doesn't expose a stop endpoint via the basic API,
    // but we can at least disconnect the streaming state on the client side.
    setState(() {});
  }

  Future<void> _createNewSession() async {
    final state = context.read<AppState>();
    await state.createSession();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final messages = state.activeMessages;
    final isStreaming = state.isStreaming;
    final hasSession = state.activeSession != null;

    return Scaffold(
      appBar: AppBar(
        leading: hasSession
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  // Navigate to sessions
                },
              )
            : null,
        title: Text(
          state.activeSession?.title ?? 'Chat',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New session',
            onPressed: _createNewSession,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: hasSession || messages.isNotEmpty
                ? _buildMessageList(messages, isStreaming, state)
                : _buildEmptyState(state),
          ),

          // Streaming thinking indicator
          if (isStreaming && state.streamingThinking != null && state.streamingThinking!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: HermesTheme.thinkingBg.withValues(alpha: 0.8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: HermesTheme.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Thinking...',
                      style: TextStyle(
                        color: HermesTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {}),
                    child: const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: HermesTheme.textMuted,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),

          // Input bar
          _buildInputBar(isStreaming, hasSession),
        ],
      ),
    );
  }

  Widget _buildMessageList(
    List<Message> messages,
    bool isStreaming,
    AppState state,
  ) {
    // Build a list of messages, appending the streaming message if active
    final displayMessages = List<Message>.from(messages);

    if (isStreaming) {
      final streamingContent = state.streamingContent ?? '';
      final streamingThinking = state.streamingThinking;

      // Add a streaming message if there's content
      if (streamingContent.isNotEmpty || streamingThinking != null) {
        displayMessages.add(Message(
          id: '__streaming__',
          role: 'assistant',
          content: streamingContent,
          thinking: streamingThinking,
          createdAt: DateTime.now(),
          toolCalls: null,
        ));
      }
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: displayMessages.length + 1, // +1 for bottom padding
      itemBuilder: (context, index) {
        if (index == displayMessages.length) {
          return const SizedBox(height: 80); // Space for the input bar
        }

        final message = displayMessages[index];
        final isStreamingMessage =
            message.id == '__streaming__';

        return MessageBubble(
          message: message,
          isStreaming: isStreamingMessage,
        );
      },
    );
  }

  Widget _buildEmptyState(AppState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 48,
            color: HermesTheme.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No active session',
            style: TextStyle(
              color: HermesTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new session to start chatting',
            style: TextStyle(
              color: HermesTheme.textMuted.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewSession,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New Session'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HermesTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isStreaming, bool hasSession) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: HermesTheme.surface,
        border: Border(
          top: BorderSide(color: HermesTheme.border, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              enabled: hasSession && !isStreaming,
              maxLines: 5,
              minLines: 1,
              style: const TextStyle(
                color: HermesTheme.textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: hasSession
                    ? (isStreaming ? 'Waiting for response...' : 'Type a message...')
                    : 'Create a session first',
                hintStyle: TextStyle(
                  color: HermesTheme.textMuted.withValues(alpha: 0.6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: HermesTheme.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isStreaming ? _stopStreaming : (_isComposing ? _sendMessage : null),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: isStreaming
                    ? null
                    : HermesTheme.primaryGradient,
                color: isStreaming ? HermesTheme.error : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isStreaming ? Icons.stop_rounded : Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}