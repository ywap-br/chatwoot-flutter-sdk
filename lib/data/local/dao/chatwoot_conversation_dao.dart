import 'dart:convert';

import 'package:chatwoot_sdk/data/local/entity/chatwoot_conversation.dart';
import 'package:hive_flutter/hive_flutter.dart';

abstract class ChatwootConversationDao {
  Future<void> saveConversation(ChatwootConversation conversation);
  Future<void> saveConversations(List<ChatwootConversation> conversations);
  ChatwootConversation? getConversation();
  List<ChatwootConversation> getConversations();
  Future<void> setActiveConversation(ChatwootConversation conversation);
  Future<void> deleteConversation();
  Future<void> onDispose();
  Future<void> clearAll();
}

//Only used when persistence is enabled
enum ChatwootConversationBoxNames {
  CONVERSATIONS,
  CLIENT_INSTANCE_TO_CONVERSATIONS
}

class PersistedChatwootConversationDao extends ChatwootConversationDao {
  //box containing all persisted conversations
  Box<ChatwootConversation> _box;

  //box with one to one relation between generated client instance id and conversation id
  final Box<String> _clientInstanceIdToConversationIdentifierBox;

  final String _clientInstanceKey;

  PersistedChatwootConversationDao(
      this._box,
      this._clientInstanceIdToConversationIdentifierBox,
      this._clientInstanceKey);

  @override
  Future<void> deleteConversation() async {
    final conversationIdentifier =
        _clientInstanceIdToConversationIdentifierBox.get(_clientInstanceKey);
    await _clientInstanceIdToConversationIdentifierBox
        .delete(_clientInstanceKey);
    await _clientInstanceIdToConversationIdentifierBox
        .delete("${_clientInstanceKey}:conversations");
    if (conversationIdentifier != null) {
      await _box.delete(int.tryParse(conversationIdentifier));
    }
  }

  @override
  Future<void> saveConversation(ChatwootConversation conversation) async {
    await _clientInstanceIdToConversationIdentifierBox.put(
        _clientInstanceKey, conversation.id.toString());
    await _box.put(conversation.id, conversation);

    // Also update persisted conversations list
    final currentList = getConversations();
    final index = currentList.indexWhere((c) => c.id == conversation.id);
    List<ChatwootConversation> updatedList;
    if (index >= 0) {
      updatedList = List.from(currentList);
      updatedList[index] = conversation;
    } else {
      updatedList = [...currentList, conversation];
    }
    final ids = updatedList.map((c) => c.id.toString()).toList();
    await _clientInstanceIdToConversationIdentifierBox.put(
        "${_clientInstanceKey}:conversations", jsonEncode(ids));
  }

  @override
  Future<void> saveConversations(List<ChatwootConversation> conversations) async {
    for (final conv in conversations) {
      await _box.put(conv.id, conv);
    }
    final ids = conversations.map((c) => c.id.toString()).toList();
    await _clientInstanceIdToConversationIdentifierBox.put(
        "${_clientInstanceKey}:conversations", jsonEncode(ids));
  }

  @override
  Future<void> setActiveConversation(ChatwootConversation conversation) async {
    await saveConversation(conversation);
  }

  @override
  ChatwootConversation? getConversation() {
    if (_box.values.length == 0) {
      return null;
    }

    final conversationidentifierString =
        _clientInstanceIdToConversationIdentifierBox.get(_clientInstanceKey);
    final conversationIdentifier =
        int.tryParse(conversationidentifierString ?? "");

    if (conversationIdentifier == null) {
      return null;
    }

    return _box.get(conversationIdentifier);
  }

  @override
  List<ChatwootConversation> getConversations() {
    final rawIds = _clientInstanceIdToConversationIdentifierBox
        .get("${_clientInstanceKey}:conversations");
    if (rawIds != null) {
      try {
        final List<dynamic> idList = jsonDecode(rawIds);
        return idList
            .map((id) => _box.get(int.tryParse(id.toString())))
            .whereType<ChatwootConversation>()
            .toList();
      } catch (_) {}
    }
    final single = getConversation();
    return single != null ? [single] : [];
  }

  @override
  Future<void> onDispose() async {}

  static Future<void> openDB() async {
    await Hive.openBox<ChatwootConversation>(
        ChatwootConversationBoxNames.CONVERSATIONS.toString());
    await Hive.openBox<String>(ChatwootConversationBoxNames
        .CLIENT_INSTANCE_TO_CONVERSATIONS
        .toString());
  }

  @override
  Future<void> clearAll() async {
    await _box.clear();
    await _clientInstanceIdToConversationIdentifierBox.clear();
  }
}

class NonPersistedChatwootConversationDao extends ChatwootConversationDao {
  ChatwootConversation? _conversation;
  List<ChatwootConversation> _conversations = [];

  @override
  Future<void> deleteConversation() async {
    _conversation = null;
    _conversations.clear();
  }

  @override
  ChatwootConversation? getConversation() {
    return _conversation;
  }

  @override
  List<ChatwootConversation> getConversations() {
    return List.unmodifiable(_conversations);
  }

  @override
  Future<void> onDispose() async {
    _conversation = null;
    _conversations.clear();
  }

  @override
  Future<void> saveConversation(ChatwootConversation conversation) async {
    _conversation = conversation;
    final index = _conversations.indexWhere((c) => c.id == conversation.id);
    if (index >= 0) {
      _conversations[index] = conversation;
    } else {
      _conversations.add(conversation);
    }
  }

  @override
  Future<void> saveConversations(List<ChatwootConversation> conversations) async {
    _conversations = List.from(conversations);
  }

  @override
  Future<void> setActiveConversation(ChatwootConversation conversation) async {
    await saveConversation(conversation);
  }

  @override
  Future<void> clearAll() async {
    _conversation = null;
    _conversations.clear();
  }
}
