import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/aura_summary_model.dart';
import '../models/daily_challenge_model.dart';
import '../models/event_access_model.dart';
import '../models/post_model.dart';
import 'founder_device_service.dart';

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

  bool _isRouteMissingError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('backend route not found') ||
        message.contains('status 404');
  }

  String _auraLevelFor(int points) {
    if (points < 500) return 'Beginner';
    if (points < 2000) return 'Builder';
    if (points < 5000) return 'Hacker';
    return 'Elite';
  }

  String _friendlyErrorMessage(http.Response response) {
    Map<String, dynamic> payload = const {};
    if (response.body.isNotEmpty) {
      try {
        payload = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        payload = const {};
      }
    }

    final rawMessage =
        (payload['error'] ?? payload['message'] ?? '').toString().trim();

    if (response.statusCode == 404) {
      return 'Backend route not found. Deploy the latest Supabase Edge Functions first.';
    }

    if (response.statusCode == 401) {
      return rawMessage.isNotEmpty
          ? rawMessage
          : 'Your session is not authorized for this action. Sign in again and retry.';
    }

    if (response.statusCode == 429) {
      return rawMessage.isNotEmpty
          ? rawMessage
          : 'Too many requests right now. Please wait a bit and try again.';
    }

    if (rawMessage.isNotEmpty) {
      return rawMessage;
    }

    return 'Request failed with status ${response.statusCode}.';
  }

  Future<Map<String, String>> _headers({
    bool includeFounderDevice = false,
  }) async {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('No authenticated session is available. Sign in again.');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'apikey': _supabaseAnonKey,
    };

    if (includeFounderDevice) {
      headers['X-Device-Id'] = await FounderDeviceService.instance.getDeviceId();
    }

    return headers;
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
    bool includeFounderDevice = false,
  }) async {
    final headers = await _headers(includeFounderDevice: includeFounderDevice);
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
      case 'PATCH':
        response = await http.patch(
          uri,
          headers: headers,
          body: jsonEncode(body ?? const {}),
        );
        break;
      default:
        throw UnsupportedError('Unsupported method: $method');
    }

    if (response.statusCode >= 400) {
      throw StateError(_friendlyErrorMessage(response));
    }

    if (response.body.isEmpty) return null;
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['data'];
  }

  Future<AuraSummaryModel> getAuraSummary([String? userId]) async {
    try {
      final data = Map<String, dynamic>.from(
        await _request(
          'GET',
          '/aura',
          queryParameters: userId == null ? null : {'userId': userId},
        ) as Map,
      );
      return AuraSummaryModel.fromJson(data);
    } catch (error) {
      if (!_isRouteMissingError(error)) rethrow;

      final resolvedUserId = userId ?? _client.auth.currentUser?.id;
      if (resolvedUserId == null) {
        throw StateError('No authenticated session is available. Sign in again.');
      }

      final data = await _client
          .from('users')
          .select(
            'id, aura_points, aura, current_streak, longest_streak, last_challenge_completed_on',
          )
          .eq('id', resolvedUserId)
          .single();

      final auraPoints =
          ((data['aura_points'] ?? data['aura'] ?? 0) as num).toInt();

      return AuraSummaryModel(
        userId: resolvedUserId,
        auraPoints: auraPoints,
        level: _auraLevelFor(auraPoints),
        currentStreak: ((data['current_streak'] ?? 0) as num).toInt(),
        longestStreak: ((data['longest_streak'] ?? 0) as num).toInt(),
        lastChallengeCompletedOn: data['last_challenge_completed_on'] == null
            ? null
            : DateTime.tryParse(data['last_challenge_completed_on'].toString()),
        badges: const [],
      );
    }
  }

  Future<List<PostModel>> getPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final data = await _request(
        'GET',
        '/posts',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      ) as List<dynamic>;

      return data
          .map(
            (item) =>
                PostModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (error) {
      if (!_isRouteMissingError(error)) rethrow;

      final from = offset;
      final to = offset + limit - 1;
      final data = await _client
          .from('posts')
          .select(
            'id, user_id, content, tags, image_url, quote_post_id, likes_count, comments_count, reposts_count, created_at',
          )
          .order('created_at', ascending: false)
          .range(from, to);

      return (data as List)
          .map((item) => PostModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
  }

  Future<List<EventAccessModel>> getEligibleEvents() async {
    try {
      final data = await _request('GET', '/events/eligible') as List<dynamic>;
      return data
          .map((item) => EventAccessModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
    } catch (error) {
      if (!_isRouteMissingError(error)) rethrow;

      final user = _client.auth.currentUser;
      if (user == null) return const [];

      try {
        final userRow = await _client
            .from('users')
            .select('aura_points, aura')
            .eq('id', user.id)
            .single();
        final auraPoints =
            ((userRow['aura_points'] ?? userRow['aura'] ?? 0) as num).toInt();

        final rows = await _client
            .from('events')
            .select('id, title, description, required_aura, link, type')
            .order('required_aura', ascending: true);

        return (rows as List)
            .map((row) {
              final event = Map<String, dynamic>.from(row as Map);
              final requiredAura = (event['required_aura'] as num? ?? 0).toInt();
              return EventAccessModel(
                id: event['id'].toString(),
                title: event['title']?.toString() ?? '',
                description: event['description']?.toString() ?? '',
                requiredAura: requiredAura,
                link: event['link']?.toString() ?? '',
                type: event['type']?.toString() ?? 'event',
                unlocked: auraPoints >= requiredAura,
                locked: auraPoints < requiredAura,
              );
            })
            .toList();
      } catch (_) {
        return const [];
      }
    }
  }

  Future<Map<String, dynamic>> createEvent({
    required String title,
    required String description,
    required int requiredAura,
    required String link,
    required String type,
  }) async {
    final data = await _request(
      'POST',
      '/events',
      includeFounderDevice: true,
      body: {
        'title': title,
        'description': description,
        'requiredAura': requiredAura,
        'link': link,
        'type': type,
      },
    ) as Map;

    return Map<String, dynamic>.from(data);
  }

  Future<List<Map<String, dynamic>>> getAdminEvents() async {
    final data = await _request(
      'GET',
      '/events',
      includeFounderDevice: true,
      queryParameters: {'includeInactive': true},
    ) as List<dynamic>;
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required int requiredAura,
    required String link,
    required String type,
    required bool isActive,
  }) async {
    final data = await _request(
      'PATCH',
      '/events/$eventId',
      includeFounderDevice: true,
      body: {
        'title': title,
        'description': description,
        'requiredAura': requiredAura,
        'link': link,
        'type': type,
        'isActive': isActive,
      },
    ) as Map;

    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> deactivateEvent(String eventId) async {
    final data = await _request(
      'POST',
      '/events/$eventId/deactivate',
      includeFounderDevice: true,
    ) as Map;
    return Map<String, dynamic>.from(data);
  }

  Future<DailyChallengeModel?> getDailyChallenge({String? techStack}) async {
    try {
      final data = Map<String, dynamic>.from(
        await _request(
          'GET',
          '/missions/daily',
          queryParameters: techStack == null ? null : {'techStack': techStack},
        ) as Map,
      );
      return DailyChallengeModel.fromJson(data);
    } catch (error) {
      if (!_isRouteMissingError(error)) {
        try {
          final legacyData = Map<String, dynamic>.from(
            await _request(
              'GET',
              '/challenges/daily',
              queryParameters: techStack == null ? null : {'techStack': techStack},
            ) as Map,
          );
          return DailyChallengeModel.fromJson(legacyData);
        } catch (_) {
          rethrow;
        }
      }

      try {
        final row = await _client
            .from('user_missions')
            .select(
              'id, mission_id, assigned_date, selected_tech_stack, completed, completed_at, is_correct',
            )
            .eq(
              'assigned_date',
              DateTime.now().toUtc().toIso8601String().split('T').first,
            )
            .order('assigned_date', ascending: false)
            .limit(1)
            .maybeSingle();

        if (row != null) {
          final mission = await _client
              .from('missions')
              .select(
                'id, title, type, tech_stack, question, options, correct_answer, link, points_reward, publish_date, is_active',
              )
              .eq('id', row['mission_id'])
              .maybeSingle();

          if (mission != null) {
            return DailyChallengeModel.fromJson({
              ...Map<String, dynamic>.from(row),
              'mission': mission,
            });
          }
        }
      } catch (_) {}

      try {
        final row = await _client
            .from('user_challenges')
            .select(
              'id, challenge_id, assigned_date, selected_tech_stack, completed, completed_at',
            )
            .order('assigned_date', ascending: false)
            .limit(1)
            .maybeSingle();

        if (row == null) return null;

        final challenge = await _client
            .from('challenges')
            .select('id, title, description, difficulty, tech_stack, points_reward')
            .eq('id', row['challenge_id'])
            .maybeSingle();

        if (challenge == null) return null;

        return DailyChallengeModel.fromJson({
          ...Map<String, dynamic>.from(row),
          'challenge': challenge,
        });
      } catch (_) {
        return null;
      }
    }
  }

  Future<Map<String, dynamic>> createChallenge({
    required String title,
    required String description,
    required String difficulty,
    required String techStack,
    required int pointsReward,
    required String publishDate,
  }) async {
    final data = await _request(
      'POST',
      '/challenges',
      includeFounderDevice: true,
      body: {
        'title': title,
        'description': description,
        'difficulty': difficulty,
        'techStack': techStack,
        'pointsReward': pointsReward,
        'publishDate': publishDate,
      },
    ) as Map;

    return Map<String, dynamic>.from(data);
  }

  Future<List<Map<String, dynamic>>> getAdminChallenges() async {
    final data = await _request(
      'GET',
      '/challenges',
      includeFounderDevice: true,
      queryParameters: {'includeInactive': true},
    ) as List<dynamic>;
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> updateChallenge({
    required String challengeId,
    required String title,
    required String description,
    required String difficulty,
    required String techStack,
    required int pointsReward,
    required bool isActive,
  }) async {
    final data = await _request(
      'PATCH',
      '/challenges/$challengeId',
      includeFounderDevice: true,
      body: {
        'title': title,
        'description': description,
        'difficulty': difficulty,
        'techStack': techStack,
        'pointsReward': pointsReward,
        'isActive': isActive,
      },
    ) as Map;

    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> deactivateChallenge(String challengeId) async {
    final data = await _request(
      'POST',
      '/challenges/$challengeId/deactivate',
      includeFounderDevice: true,
    ) as Map;
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>?> getDailyMission({String? techStack}) async {
    final data = await _request(
      'GET',
      '/missions/daily',
      queryParameters: techStack == null ? null : {'techStack': techStack},
    );

    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>?> getTodayMissionAssignment() async {
    final data = await _request('GET', '/missions/today');
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> submitDailyMission({
    String answerSubmitted = '',
    String submissionLink = '',
  }) async {
    final data = await _request(
      'POST',
      '/missions/submit',
      body: {
        'answerSubmitted': answerSubmitted,
        'submissionLink': submissionLink,
      },
    ) as Map;

    return Map<String, dynamic>.from(data);
  }

  Future<List<Map<String, dynamic>>> getAdminMissions() async {
    final data = await _request(
      'GET',
      '/missions',
      includeFounderDevice: true,
      queryParameters: {'includeInactive': true},
    ) as List<dynamic>;

    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> createMission({
    required String title,
    required String type,
    required String techStack,
    required String question,
    List<dynamic>? options,
    String? correctAnswer,
    String? link,
    required int pointsReward,
    required String publishDate,
    bool isActive = true,
  }) async {
    final data = await _request(
      'POST',
      '/missions',
      includeFounderDevice: true,
      body: {
        'title': title,
        'type': type,
        'techStack': techStack,
        'question': question,
        'options': options,
        'correctAnswer': correctAnswer,
        'link': link,
        'pointsReward': pointsReward,
        'publishDate': publishDate,
        'isActive': isActive,
      },
    ) as Map;

    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> updateMission({
    required String missionId,
    String? title,
    String? type,
    String? techStack,
    String? question,
    List<dynamic>? options,
    String? correctAnswer,
    String? link,
    int? pointsReward,
    String? publishDate,
    bool? isActive,
  }) async {
    final data = await _request(
      'PATCH',
      '/missions/$missionId',
      includeFounderDevice: true,
      body: {
        if (title != null) 'title': title,
        if (type != null) 'type': type,
        if (techStack != null) 'techStack': techStack,
        if (question != null) 'question': question,
        if (options != null) 'options': options,
        if (correctAnswer != null) 'correctAnswer': correctAnswer,
        if (link != null) 'link': link,
        if (pointsReward != null) 'pointsReward': pointsReward,
        if (publishDate != null) 'publishDate': publishDate,
        if (isActive != null) 'isActive': isActive,
      },
    ) as Map;

    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> deactivateMission(String missionId) async {
    final data = await _request(
      'POST',
      '/missions/$missionId/deactivate',
      includeFounderDevice: true,
    ) as Map;

    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> reviewMissionAssignment({
    required String assignmentId,
    required bool isCorrect,
  }) async {
    final data = await _request(
      'POST',
      '/missions/assignments/$assignmentId/review',
      includeFounderDevice: true,
      body: {'isCorrect': isCorrect},
    ) as Map;

    return Map<String, dynamic>.from(data);
  }

  Future<bool> hasFounderAccess() async {
    try {
      final data = Map<String, dynamic>.from(
        await _request(
          'GET',
          '/users/founder-access',
          includeFounderDevice: true,
        ) as Map,
      );
      return data['authorized'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> completeDailyChallenge({
    String submissionText = '',
    String submissionLink = '',
  }) async {
    try {
      final data = await _request(
        'POST',
        '/missions/submit',
        body: {
          'answerSubmitted': submissionText,
          'submissionLink': submissionLink,
        },
      ) as Map;

      return Map<String, dynamic>.from(data);
    } catch (error) {
      if (!_isRouteMissingError(error)) {
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

      try {
        final data = await _client.rpc(
          'submit_daily_mission',
          params: {
            'p_answer_submitted': submissionText,
            'p_submission_link': submissionLink,
          },
        );
        return Map<String, dynamic>.from(data as Map);
      } catch (_) {}

      final data = await _client.rpc(
        'complete_daily_challenge',
        params: {
          'p_submission_text': submissionText,
          'p_submission_link': submissionLink,
        },
      );
      return Map<String, dynamic>.from(data as Map);
    }
  }
}
