import 'dart:async';
import 'package:http/http.dart' as http;

class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
  factory AppException.fromStatusCode(int code, {String? serverMessage}) {
    switch (code) {
      case 400:
        return AppException(serverMessage ?? 'That input looks invalid — check the fields and try again.', statusCode: 400);
      case 401:
        return AppException('Your session has expired — please sign in again.', statusCode: 401);
      case 403:
        return AppException("You don't have access to that.", statusCode: 403);
      case 404:
        return AppException('Could not find that — it may have been removed.', statusCode: 404);
      case 429:
        return AppException('Too many requests — wait a moment and try again.', statusCode: 429);
      case 502:
        return AppException('The AI provider did not respond correctly. Try again.', statusCode: 502);
      default:
        return AppException(serverMessage ?? 'Something went wrong. Try again.', statusCode: code);
    }
  }
}

String errorMessage(Object error, {String fallback = 'Something went wrong. Try again.'}) {
  if (error is AppException) return error.message;
  if (error is ArgumentError) return error.message.toString();
  if (error is TimeoutException) return 'The server took too long to respond.. Try again!.';
  if (error is http.ClientException) return "Can't reach the server. Check your connection and try again.";
  return fallback;
}
