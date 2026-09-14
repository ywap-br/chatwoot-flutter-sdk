import 'package:chatwoot_sdk/chatwoot_sdk.dart';
import 'package:chatwoot_sdk/data/local/local_storage.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
part 'chatwoot_conversation.g.dart';

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: CHATWOOT_CONVERSATION_HIVE_TYPE_ID)
class ChatwootConversation extends Equatable {
  ///The numeric ID of the conversation
  @JsonKey()
  @HiveField(0)
  final int id;

  ///The numeric ID of the inbox
  @JsonKey(name: "inbox_id")
  @HiveField(1)
  final int inboxId;

  ///List of all messages from the conversation
  @JsonKey(defaultValue: <ChatwootMessage>[])
  @HiveField(2)
  final List<ChatwootMessage> messages;

  ///Contact of the conversation
  @JsonKey()
  @HiveField(3)
  final ChatwootContact contact;

  ///Status of the conversation ("open", "resolved", "pending", "snoozed")
  @JsonKey()
  @HiveField(4)
  final String? status;

  ///Creation timestamp of the conversation
  @JsonKey(name: "created_at")
  @HiveField(5)
  final dynamic createdAt;

  ///Unread messages count
  @JsonKey(name: "unread_count")
  @HiveField(6)
  final int? unreadCount;

  ChatwootConversation({
    required this.id,
    required this.inboxId,
    this.messages = const [],
    required this.contact,
    this.status,
    this.createdAt,
    this.unreadCount,
  });

  factory ChatwootConversation.fromJson(Map<String, dynamic> json) =>
      _$ChatwootConversationFromJson(json);

  Map<String, dynamic> toJson() => _$ChatwootConversationToJson(this);

  @override
  List<Object?> get props =>
      [id, inboxId, messages, contact, status, createdAt, unreadCount];
}
