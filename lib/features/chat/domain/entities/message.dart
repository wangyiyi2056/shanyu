/// 消息角色
enum MessageRole {
  user,
  assistant,
  tool,
  system,
}

/// 消息类型
enum MessageType {
  text,
  toolCall,
  toolResult,
  actionCard,
  image,
}

/// 聊天消息
class Message {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final MessageType messageType;
  final String? intent;
  final Map<String, dynamic>? toolCall;
  final String? toolCallId;
  final String? imageUrl;
  final List<ActionCard> actionCards;
  final String syncStatus;

  const Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.messageType = MessageType.text,
    this.intent,
    this.toolCall,
    this.toolCallId,
    this.imageUrl,
    this.actionCards = const [],
    this.syncStatus = 'pending',
  });

  Message copyWith({
    String? id,
    String? conversationId,
    MessageRole? role,
    String? content,
    DateTime? createdAt,
    MessageType? messageType,
    String? intent,
    Map<String, dynamic>? toolCall,
    String? toolCallId,
    String? imageUrl,
    List<ActionCard>? actionCards,
    String? syncStatus,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      messageType: messageType ?? this.messageType,
      intent: intent ?? this.intent,
      toolCall: toolCall ?? this.toolCall,
      toolCallId: toolCallId ?? this.toolCallId,
      imageUrl: imageUrl ?? this.imageUrl,
      actionCards: actionCards ?? this.actionCards,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

/// 操作卡片
class ActionCard {
  final String id;
  final String label;
  final String action;
  final ActionCardType type;

  const ActionCard({
    required this.id,
    required this.label,
    required this.action,
    this.type = ActionCardType.button,
  });
}

enum ActionCardType {
  button,
  link,
  input,
}
