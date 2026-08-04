/// Hermes API response models
/// Mirrors the Hermes Agent REST API types.

class StatusResponse {
  final String version;
  final String state;
  final String? activeProfile;
  final bool backendReady;
  final Map<String, dynamic>? platforms;

  StatusResponse({
    required this.version,
    required this.state,
    this.activeProfile,
    required this.backendReady,
    this.platforms,
  });

  factory StatusResponse.fromJson(Map<String, dynamic> json) {
    return StatusResponse(
      version: json['version'] as String? ?? '',
      state: json['state'] as String? ?? 'unknown',
      activeProfile: json['active_profile'] as String?,
      backendReady: json['backend_ready'] as bool? ?? false,
      platforms: json['platforms'] as Map<String, dynamic>?,
    );
  }
}

class SessionInfo {
  final String id;
  final String? title;
  final String? model;
  final String? provider;
  final int messageCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;
  final bool pinned;
  final String? source;

  SessionInfo({
    required this.id,
    this.title,
    this.model,
    this.provider,
    required this.messageCount,
    required this.createdAt,
    required this.updatedAt,
    this.archived = false,
    this.pinned = false,
    this.source,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      id: json['id'] as String? ?? '',
      title: json['title'] as String?,
      model: json['model'] as String?,
      provider: json['provider'] as String?,
      messageCount: json['message_count'] as int? ?? 0,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      archived: json['archived'] as bool? ?? false,
      pinned: json['pinned'] as bool? ?? false,
      source: json['source'] as String?,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}

class SessionListResponse {
  final List<SessionInfo> sessions;
  final int total;
  final bool hasMore;

  SessionListResponse({
    required this.sessions,
    required this.total,
    required this.hasMore,
  });

  factory SessionListResponse.fromJson(Map<String, dynamic> json) {
    final sessionsList = (json['sessions'] as List<dynamic>?)
            ?.map((e) => SessionInfo.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return SessionListResponse(
      sessions: sessionsList,
      total: json['total'] as int? ?? sessionsList.length,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}

class Message {
  final String id;
  final String role;
  final String content;
  final String? name;
  final DateTime createdAt;
  final List<ToolCall>? toolCalls;
  final String? thinking;
  final Map<String, dynamic>? raw;

  Message({
    required this.id,
    required this.role,
    required this.content,
    this.name,
    required this.createdAt,
    this.toolCalls,
    this.thinking,
    this.raw,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      name: json['name'] as String?,
      createdAt: _parseDateTime(json['created_at']),
      toolCalls: (json['tool_calls'] as List<dynamic>?)
          ?.map((e) => ToolCall.fromJson(e as Map<String, dynamic>))
          .toList(),
      thinking: json['thinking'] as String?,
      raw: json,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}

class ToolCall {
  final String id;
  final String name;
  final String arguments;
  final String? result;
  final String? status;

  ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
    this.result,
    this.status,
  });

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      arguments: _jsonOrString(json['arguments']),
      result: json['result'] as String?,
      status: json['status'] as String?,
    );
  }

  static String _jsonOrString(dynamic value) {
    if (value is String) return value;
    if (value is Map || value is List) {
      return value.toString();
    }
    return value?.toString() ?? '';
  }
}

class ModelInfo {
  final String id;
  final String provider;
  final String? displayName;
  final bool supportsStreaming;
  final int? contextLength;

  ModelInfo({
    required this.id,
    required this.provider,
    this.displayName,
    this.supportsStreaming = true,
    this.contextLength,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      id: json['id'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      displayName: json['display_name'] as String?,
      supportsStreaming: json['supports_streaming'] as bool? ?? true,
      contextLength: json['context_length'] as int?,
    );
  }
}

class ModelInfoResponse {
  final String? currentModel;
  final String? currentProvider;
  final List<ModelInfo>? availableModels;

  ModelInfoResponse({
    this.currentModel,
    this.currentProvider,
    this.availableModels,
  });

  factory ModelInfoResponse.fromJson(Map<String, dynamic> json) {
    return ModelInfoResponse(
      currentModel: json['current_model'] as String?,
      currentProvider: json['current_provider'] as String?,
      availableModels: (json['models'] as List<dynamic>?)
          ?.map((e) => ModelInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SkillInfo {
  final String name;
  final String? description;
  final String? category;
  final bool enabled;

  SkillInfo({
    required this.name,
    this.description,
    this.category,
    this.enabled = true,
  });

  factory SkillInfo.fromJson(Map<String, dynamic> json) {
    return SkillInfo(
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String?,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

class MemoryStatus {
  final String? provider;
  final int? entryCount;
  final bool enabled;

  MemoryStatus({
    this.provider,
    this.entryCount,
    this.enabled = true,
  });

  factory MemoryStatus.fromJson(Map<String, dynamic> json) {
    return MemoryStatus(
      provider: json['provider'] as String?,
      entryCount: json['entry_count'] as int?,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

class CronJobInfo {
  final String id;
  final String? name;
  final String schedule;
  final bool enabled;
  final String? lastRun;
  final String? nextRun;

  CronJobInfo({
    required this.id,
    this.name,
    required this.schedule,
    this.enabled = true,
    this.lastRun,
    this.nextRun,
  });

  factory CronJobInfo.fromJson(Map<String, dynamic> json) {
    return CronJobInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      schedule: json['schedule'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      lastRun: json['last_run'] as String?,
      nextRun: json['next_run'] as String?,
    );
  }
}

class WebhookInfo {
  final String id;
  final String? name;
  final String url;
  final bool enabled;

  WebhookInfo({
    required this.id,
    this.name,
    required this.url,
    this.enabled = true,
  });

  factory WebhookInfo.fromJson(Map<String, dynamic> json) {
    return WebhookInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      url: json['url'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

enum GatewayConnectionState {
  idle,
  connecting,
  open,
  closed,
  error;

  static GatewayConnectionState fromString(String s) {
    switch (s) {
      case 'connecting':
        return GatewayConnectionState.connecting;
      case 'open':
        return GatewayConnectionState.open;
      case 'closed':
        return GatewayConnectionState.closed;
      case 'error':
        return GatewayConnectionState.error;
      default:
        return GatewayConnectionState.idle;
    }
  }
}

enum GatewayEventType {
  gatewayReady,
  sessionInfo,
  messageStart,
  messageDelta,
  messageInterim,
  messageComplete,
  thinkingDelta,
  reasoningDelta,
  reasoningAvailable,
  statusUpdate,
  toolStart,
  toolProgress,
  toolComplete,
  toolGenerating,
  clarifyRequest,
  approvalRequest,
  error,
  unknown;

  static GatewayEventType fromString(String s) {
    switch (s) {
      case 'gateway.ready':
        return GatewayEventType.gatewayReady;
      case 'session.info':
        return GatewayEventType.sessionInfo;
      case 'message.start':
        return GatewayEventType.messageStart;
      case 'message.delta':
        return GatewayEventType.messageDelta;
      case 'message.interim':
        return GatewayEventType.messageInterim;
      case 'message.complete':
        return GatewayEventType.messageComplete;
      case 'thinking.delta':
        return GatewayEventType.thinkingDelta;
      case 'reasoning.delta':
        return GatewayEventType.reasoningDelta;
      case 'reasoning.available':
        return GatewayEventType.reasoningAvailable;
      case 'status.update':
        return GatewayEventType.statusUpdate;
      case 'tool.start':
        return GatewayEventType.toolStart;
      case 'tool.progress':
        return GatewayEventType.toolProgress;
      case 'tool.complete':
        return GatewayEventType.toolComplete;
      case 'tool.generating':
        return GatewayEventType.toolGenerating;
      case 'clarify.request':
        return GatewayEventType.clarifyRequest;
      case 'approval.request':
        return GatewayEventType.approvalRequest;
      case 'error':
        return GatewayEventType.error;
      default:
        return GatewayEventType.unknown;
    }
  }
}

class GatewayEvent {
  final GatewayEventType type;
  final String? sessionId;
  final String? profile;
  final Map<String, dynamic>? payload;

  GatewayEvent({
    required this.type,
    this.sessionId,
    this.profile,
    this.payload,
  });

  factory GatewayEvent.fromJson(Map<String, dynamic> json) {
    return GatewayEvent(
      type: GatewayEventType.fromString(json['type'] as String? ?? ''),
      sessionId: json['session_id'] as String?,
      profile: json['profile'] as String?,
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }
}