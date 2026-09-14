import 'package:chatwoot_sdk/chatwoot_sdk.dart';
import 'package:chatwoot_sdk/data/local/local_storage.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
part 'chatwoot_conversation.g.dart';

/// Chatwoot conversation lifecycle status. See [chatwootConversationStatusFromString]
/// for how the raw API string maps here, and [ChatwootConversation.statusEnum]
/// for the typed accessor.
enum ChatwootConversationStatus { open, pending, resolved, snoozed }

/// Parses a raw `status` string from the Chatwoot API/websocket into a
/// [ChatwootConversationStatus]. Unknown or missing values default to
/// [ChatwootConversationStatus.open] -- the same default the UI already
/// assumed before conversations carried an explicit status.
ChatwootConversationStatus chatwootConversationStatusFromString(
    String? status) {
  switch (status?.toLowerCase()) {
    case "resolved":
      return ChatwootConversationStatus.resolved;
    case "pending":
      return ChatwootConversationStatus.pending;
    case "snoozed":
      return ChatwootConversationStatus.snoozed;
    case "open":
    default:
      return ChatwootConversationStatus.open;
  }
}

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

  ///Status of the conversation ("open", "resolved", "pending", "snoozed").
  /// See [statusEnum] for the typed accessor.
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

  ///When [status] is "snoozed", the ISO-8601 timestamp the conversation
  ///comes back to the agent's queue (e.g. "2026-09-14T22:52:37.000Z").
  ///Null for every other status.
  @JsonKey(name: "snoozed_until")
  @HiveField(7)
  final String? snoozedUntil;

  ChatwootConversation({
    required this.id,
    required this.inboxId,
    this.messages = const [],
    required this.contact,
    this.status,
    this.createdAt,
    this.unreadCount,
    this.snoozedUntil,
  });

  /// Typed accessor for [status]. See [chatwootConversationStatusFromString].
  ChatwootConversationStatus get statusEnum =>
      chatwootConversationStatusFromString(status);

  factory ChatwootConversation.fromJson(Map<String, dynamic> json) =>
      _$ChatwootConversationFromJson(json);

  Map<String, dynamic> toJson() => _$ChatwootConversationToJson(this);

  /// Returns a copy of this conversation with the given fields replaced.
  ChatwootConversation copyWith({
    int? id,
    int? inboxId,
    List<ChatwootMessage>? messages,
    ChatwootContact? contact,
    String? status,
    dynamic createdAt,
    int? unreadCount,
    String? snoozedUntil,
  }) {
    return ChatwootConversation(
      id: id ?? this.id,
      inboxId: inboxId ?? this.inboxId,
      messages: messages ?? this.messages,
      contact: contact ?? this.contact,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      unreadCount: unreadCount ?? this.unreadCount,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
    );
  }

  /// Returns a copy with [status] (and, when snoozed, [snoozedUntil])
  /// authoritatively replaced. Unlike [copyWith] -- which treats every
  /// argument as "replace if non-null, else keep the old value" -- this
  /// always overwrites [snoozedUntil], including clearing it back to null.
  /// A status transition away from "snoozed" must drop the old timestamp
  /// rather than keep it, which `copyWith(snoozedUntil: null)` cannot
  /// express.
  ChatwootConversation withStatus(String status, {String? snoozedUntil}) {
    return ChatwootConversation(
      id: id,
      inboxId: inboxId,
      messages: messages,
      contact: contact,
      status: status,
      createdAt: createdAt,
      unreadCount: unreadCount,
      snoozedUntil: snoozedUntil,
    );
  }

  @override
  List<Object?> get props => [
        id,
        inboxId,
        messages,
        contact,
        status,
        createdAt,
        unreadCount,
        snoozedUntil,
      ];
}
