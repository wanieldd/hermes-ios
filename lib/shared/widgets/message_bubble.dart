import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../core/api/models.dart';
import '../theme/hermes_theme.dart';

/// A reusable chat message bubble with role-based styling.
class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isStreaming;

  const MessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _showThinking = false;
  bool _showToolCalls = false;

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isUser = message.role == 'user';
    final isSystem = message.role == 'system';

    if (isSystem) {
      return _buildSystemMessage(message);
    }

    final bubbleColor = isUser ? HermesTheme.userBubble : HermesTheme.assistantBubble;
    final textColor = isUser ? Colors.white : HermesTheme.textPrimary;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: align,
        children: [
          // Role label
          if (!isUser && message.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                message.role == 'assistant' ? 'Hermes' : message.role,
                style: const TextStyle(
                  fontSize: 12,
                  color: HermesTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Thinking block
          if (message.thinking != null && message.thinking!.isNotEmpty)
            _buildThinkingBlock(),

          // Tool calls
          if (message.toolCalls != null && message.toolCalls!.isNotEmpty)
            _buildToolCalls(),

          // Message content
          if (message.content.isNotEmpty)
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.82,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 14),
                ),
              ),
              child: isUser
                  ? Text(
                      message.content,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    )
                  : MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet.fromTheme(
                        Theme.of(context),
                      ).copyWith(
                        p: const TextStyle(
                          color: HermesTheme.textPrimary,
                          fontSize: 15,
                          height: 1.5,
                        ),
                        code: const TextStyle(
                          color: HermesTheme.accent,
                          backgroundColor: HermesTheme.surfaceLight,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: HermesTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        blockquoteDecoration: BoxDecoration(
                          color: HermesTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                          border: const Border(
                            left: BorderSide(
                              color: HermesTheme.primary,
                              width: 3,
                            ),
                          ),
                        ),
                        h1: const TextStyle(
                          color: HermesTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        h2: const TextStyle(
                          color: HermesTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        h3: const TextStyle(
                          color: HermesTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        strong: const TextStyle(
                          color: HermesTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        em: const TextStyle(
                          color: HermesTheme.textPrimary,
                          fontStyle: FontStyle.italic,
                        ),
                        a: const TextStyle(
                          color: HermesTheme.accent,
                          decoration: TextDecoration.underline,
                        ),
                        listBullet: const TextStyle(
                          color: HermesTheme.textPrimary,
                        ),
                        tableBorder: TableBorder.all(
                          color: HermesTheme.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        tableHead: const TextStyle(
                          color: HermesTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        tableBody: const TextStyle(
                          color: HermesTheme.textPrimary,
                          fontSize: 13,
                        ),
                        horizontalRuleDecoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: HermesTheme.border),
                          ),
                        ),
                      ),
                    ),
            ),

          // Streaming indicator
          if (widget.isStreaming && message.content.isEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: _StreamingDots(),
            ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(Message message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: HermesTheme.systemBubble,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline,
                color: HermesTheme.success, size: 14),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                message.content,
                style: const TextStyle(
                  color: HermesTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingBlock() {
    final thinking = widget.message.thinking ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _showThinking = !_showThinking),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: HermesTheme.thinkingBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: HermesTheme.thinkingBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showThinking
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: HermesTheme.textMuted,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Thinking',
                    style: TextStyle(
                      fontSize: 12,
                      color: HermesTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showThinking)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: HermesTheme.thinkingBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: HermesTheme.thinkingBorder),
              ),
              child: Text(
                thinking,
                style: const TextStyle(
                  color: HermesTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolCalls() {
    final toolCalls = widget.message.toolCalls ?? [];
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _showToolCalls = !_showToolCalls),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: HermesTheme.toolCallBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: HermesTheme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.handyman_outlined,
                      size: 14, color: HermesTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${toolCalls.length} tool call${toolCalls.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: HermesTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    _showToolCalls
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: HermesTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_showToolCalls)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                children: toolCalls.map((tc) {
                  final statusColor = switch (tc.status) {
                    'completed' => HermesTheme.success,
                    'error' => HermesTheme.error,
                    _ => HermesTheme.warning,
                  };
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: HermesTheme.toolCallBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: HermesTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.terminal_rounded,
                                size: 14, color: statusColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                tc.name,
                                style: const TextStyle(
                                  color: HermesTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            Icon(Icons.circle, size: 8, color: statusColor),
                          ],
                        ),
                        if (tc.arguments.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              tc.arguments,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: HermesTheme.textMuted,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        if (tc.result != null && tc.result!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              tc.result!,
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: HermesTheme.textSecondary,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Animated dots shown while the agent is generating a response.
class _StreamingDots extends StatefulWidget {
  @override
  State<_StreamingDots> createState() => _StreamingDotsState();
}

class _StreamingDotsState extends State<_StreamingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = ((_animation.value + i * 0.2) % 1.0);
            final opacity = 0.3 + (phase < 0.5 ? phase * 1.4 : (1 - phase) * 1.4);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: HermesTheme.primary.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}