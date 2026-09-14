import 'package:dio/dio.dart';

/// {@category FlutterClientSdk}
class ChatwootClientException implements Exception {
  String cause;
  dynamic data;
  ChatwootClientExceptionType type;

  ChatwootClientException(this.cause, this.type, {this.data});

  static String extractError(dynamic e) {
    if (e is DioException) {
      if (e.response?.data != null) {
        return "${e.response?.statusCode}: ${e.response?.data}";
      }
      if (e.error != null) {
        return e.error.toString();
      }
      if (e.message != null && e.message!.isNotEmpty) {
        return e.message!;
      }
      return e.toString();
    }
    return e.toString();
  }

  @override
  String toString() => "ChatwootClientException: [$type] $cause";
}

/// {@category FlutterClientSdk}
enum ChatwootClientExceptionType {
  CREATE_CLIENT_FAILED,
  SEND_MESSAGE_FAILED,
  CREATE_CONTACT_FAILED,
  CREATE_CONVERSATION_FAILED,
  GET_MESSAGES_FAILED,
  GET_CONTACT_FAILED,
  GET_CONVERSATION_FAILED,
  UPDATE_CONTACT_FAILED,
  UPDATE_MESSAGE_FAILED
}
