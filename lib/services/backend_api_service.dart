import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/aura_summary_model.dart';
import '../models/daily_challenge_model.dart';
import '../models/event_access_model.dart';

class BackendApiService {
  BackendApiService._internal();
  static final BackendApiService instance = BackendApiService._internal();
  static const String _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hybvsgxqstnxamdkijsk.supabase.co',
  );
  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_PawpVpaKL2oGSMNT92IzkA_wjiORWQ4',
  );

  SupabaseClient get _client => Supabase.instance.client;

  Future<Map<String, String>> _headers() async {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('No authenticated session is available.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'apikey': _supabaseAnonKey,
    };
  }

  Uri _uri(String path, [Map<String, dynamic>? queryParameters]) {
    final base = Uri.parse(_supabaseUrl);
    return base.replace(
      path: '${base.path}/functions/v1$path',
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? body,
  }) async {
    final headers = await _headers();
    final uri = _uri(path, queryParameters);

    late final http.Response response;
    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? const {}),
        );
        break;
      case 'DELETE':
        response = await http.delete(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
        break;
      default:
        throw UnsupportedError('Unsupported method: $method');
    }

    if (response.statusCode >= 400) {
      final payload = response.body.isEmpty
          ? const <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      throw StateError(
        (payload['error'] ??
                'Request failed with status ${response.statusCode}')
            .toString(),
      );
    }

    if (response.body.isEmpty) return null;
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['data'];
  }

  Future<AuraSummaryModel> getAuraSummary([String? userId]) async {
    final data = Map<String, dynamic>.from(
      await _request(
        'GET',
        '/aura',
        queryParameters: userId == null ? null : {'userId': userId},
      ) as Map,
    );
    return AuraSummaryModel.fromJson(data);
  }

  Future<List<EventAccessModel>> getEligibleEvents() async {
    final data = await _request('GET', '/events/eligible') as List<dynamic>;
    return data
        .map((item) => EventAccessModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }

  Future<DailyChallengeModel> getDailyChallenge({String? techStack}) async {
    final data = Map<String, dynamic>.from(
      await _request(
        'GET',
        '/challenges/daily',
        queryParameters: techStack == null ? null : {'techStack': techStack},
      ) as Map,
    );
    return DailyChallengeModel.fromJson(data);
  }

  Future<Map<String, dynamic>> completeDailyChallenge({
    String submissionText = '',
    String submissionLink = '',
  }) async {
    final data = await _request(
      'POST',
      '/challenges/complete',
      body: {
        'submissionText': submissionText,
        'submissionLink': submissionLink,
      },
    ) as Map;

    return Map<String, dynamic>.from(data);
  }
}
