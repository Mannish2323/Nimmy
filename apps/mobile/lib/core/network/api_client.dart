import 'dart:convert';

import 'package:dio/dio.dart';

/// Network boundary for the optional Python AI service.
///
/// The verified MVP uses an explicit local intent parser. This client never
/// fabricates tool calls, memories, feedback delivery, or future capabilities
/// when the backend is unavailable.
class NimmyApiClient {
  NimmyApiClient({required String baseUrl})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 8),
          headers: const {
            'Content-Type': 'application/json',
            'X-Client-ID': 'nimmy-flutter-mobile',
          },
        ),
      );

  final Dio _dio;

  Future<Map<String, dynamic>> sendChatMessage(
    String prompt, {
    required String accessToken,
    String sessionId = 'mobile-session',
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/chat',
        data: jsonEncode({
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'session_id': sessionId,
        }),
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      final data = response.data;
      if (response.statusCode == 200 && data != null) return data;
      throw const NimmyApiException(
        'The AI service returned an invalid response.',
      );
    } on DioException catch (error) {
      throw NimmyApiException(
        'Nimmy\'s AI service is temporarily unavailable.',
        cause: error,
      );
    }
  }
}

class NimmyApiException implements Exception {
  const NimmyApiException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'NimmyApiException: $message';
}
