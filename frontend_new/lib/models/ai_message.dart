// lib/models/ai_message.dart

import 'ai_action.dart';  // ✅ Import AiAction

enum MessageRole { user, assistant, system }
enum MessageStatus { sending, sent, error }

class AiMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final MessageStatus status;
  final AiAction? action;

  AiMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.action,
  });

  factory AiMessage.user(String content) {
    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );
  }

  factory AiMessage.assistant(String content, {AiAction? action}) {
    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      action: action,
    );
  }

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    return AiMessage(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['content']?.toString() ?? '',
      role: _parseRole(json['role']?.toString()),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: MessageStatus.sent,
      action: json['action'] != null ? AiAction.fromJson(json['action']) : null,
    );
  }

  static MessageRole _parseRole(String? role) {
    switch (role) {
      case 'user':
        return MessageRole.user;
      case 'assistant':
        return MessageRole.assistant;
      case 'system':
        return MessageRole.system;
      default:
        return MessageRole.assistant;
    }
  }

  AiMessage copyWith({
    String? content,
    MessageStatus? status,
    AiAction? action,
  }) {
    return AiMessage(
      id: id,
      content: content ?? this.content,
      role: role,
      timestamp: timestamp,
      status: status ?? this.status,
      action: action ?? this.action,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'role': role.name,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'action': action?.toJson(),
    };
  }
}