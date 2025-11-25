import 'package:dio/dio.dart';
import 'constants.dart';

class TokenService {
  final Dio _dio = Dio();

  Future<String> fetchChatToken(String userId) async {
    try {
      final response = await _dio.get(
        '$apiBaseUrl/chat-token',
        queryParameters: {'userId': userId},
      );

      if (response.statusCode == 200) {
        return response.data['chatToken'];
      } else {
        throw Exception('Failed to load chat token');
      }
    } catch (e) {
      throw Exception('Error fetching chat token: $e');
    }
  }

  Future<Map<String, dynamic>> fetchRtcToken(
    String channelName,
    String uid,
  ) async {
    try {
      final response = await _dio.get(
        '$apiBaseUrl/rtc-token',
        queryParameters: {'channelName': channelName, 'uid': uid},
      );

      if (response.statusCode == 200) {
        return {
          'rtcToken': response.data['rtcToken'],
          'uid': response.data['uid'],
        };
      } else {
        throw Exception('Failed to load RTC token');
      }
    } catch (e) {
      throw Exception('Error fetching RTC token: $e');
    }
  }
}
