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

  String _cleanErrorText(Object error) {
    final message = error.toString().trim();
    const badStatePrefix = 'Bad state: ';
    if (message.startsWith(badStatePrefix)) {
      return message.substring(badStatePrefix.length).trim();
    }
    return message;
  }

  List<String> _stackCandidates(String raw) {
    return raw
        .split(',')
        .map((part) => part.trim().toLowerCase())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>?> _resolveTodayMissionFallback({
    String? techStack,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final today = DateTime.now().toIso8601String().split('T').first;

    final userRow = await _client
        .from('users')
        .select('stack')
        .eq('id', user.id)
        .maybeSingle();

    final requestedCandidates = <String>{};
    if (techStack != null && techStack.trim().isNotEmpty) {
      requestedCandidates.addAll(_stackCandidates(techStack));
      requestedCandidates.add(techStack.trim().toLowerCase());
    }

    final rawStacks = (userRow?['stack'] as List?) ?? const [];
    for (final item in rawStacks) {
      final value = item.toString().trim();
      if (value.isEmpty) continue;
      requestedCandidates.add(value.toLowerCase());
      requestedCandidates.addAll(_stackCandidates(value));
    }
    requestedCandidates.add('general');

    final missionRows = await _client
        .from('missions')
        .select(
          'id, title, type, tech_stack, question, options, correct_answer, link, points_reward, publish_date, is_active',
        )
        .eq('is_active', true)
        .eq('publish_date', today)
        .order('created_at', ascending: false);

    if (missionRows is! List || missionRows.isEmpty) {
      return null;
    }

    Map<String, dynamic>? matchedMission;
    for (final row in missionRows) {
      final mission = Map<String, dynamic>.from(row as Map);
      final missionStack = mission['tech_stack']?.toString().trim() ?? '';
      final missionCandidates = <String>{
        missionStack.toLowerCase(),
        ..._stackCandidates(missionStack),
      }..remove('');

      if (missionCandidates.any(requestedCandidates.contains)) {
        matchedMission = mission;
        break;
      }
    }

    matchedMission ??= missionRows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .firstWhere(
          (mission) =>
              (mission['tech_stack']?.toString().trim().toLowerCase() ?? '') ==
              'general',
          orElse: () => Map<String, dynamic>.from(missionRows.first as Map),
        );

    return {
      'id': '',
      'mission_id': matchedMission['id'],
      'assigned_date': today,
      'selected_tech_stack': requestedCandidates.first,
      'completed': false,
      'completed_at': null,
      'is_correct': false,
      'mission': matchedMission,
    };
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
    try {
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
    } catch (error) {
      if (!_isRouteMissingError(error)) rethrow;

      final data = await _client
          .from('events')
          .insert({
            'title': title.trim(),
            'description': description.trim(),
            'required_aura': requiredAura,
            'link': link.trim(),
            'type': type.trim(),
            'is_active': true,
            'created_by': _client.auth.currentUser?.id,
          })
          .select(
            'id, title, description, required_aura, link, type, is_active, created_by, created_at, updated_at',
          )
          .single();

      return Map<String, dynamic>.from(data);
    }
  }

  Future<List<Map<String, dynamic>>> getAdminEvents() async {
    try {
      final data = await _request(
        'GET',
        '/events',
        includeFounderDevice: true,
        queryParameters: {'includeInactive': true},
      ) as List<dynamic>;
      return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (error) {
      if (!_isRouteMissingError(error)) rethrow;

      final data = await _client
          .from('events')
          .select(
            'id, title, description, required_aura, link, type, is_active, created_by, created_at, updated_at',
          )
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
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
    try {
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
    } catch (error) {
      if (!_isRouteMissingError(error)) rethrow;

      final data = await _client
          .from('events')
          .update({
            'title': title.trim(),
            'description': description.trim(),
            'required_aura': requiredAura,
            'link': link.trim(),
            'type': type.trim(),
            'is_active': isActive,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', eventId)
          .select(
            'id, title, description, required_aura, link, type, is_active, created_by, created_at, updated_at',
          )
          .single();

      return Map<String, dynamic>.from(data);
    }
  }

  Future<Map<String, dynamic>> deactivateEvent(String eventId) async {
    try {
      final data = await _request(
        'POST',
        '/events/$eventId/deactivate',
        includeFounderDevice: true,
      ) as Map;
      return Map<String, dynamic>.from(data);
    } catch (error) {
      if (!_isRouteMissingError(error)) rethrow;

      final data = await _client
          .from('events')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', eventId)
          .select(
            'id, title, description, required_aura, link, type, is_active, created_by, created_at, updated_at',
          )
          .single();

      return Map<String, dynamic>.from(data);
    }
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
        rethrow;
      }

      try {
        final user = _client.auth.currentUser;
        if (user == null) return null;

        final today = DateTime.now().toIso8601String().split('T').first;
        Map<String, dynamic>? row = await _client
            .from('user_missions')
            .select(
              'id, mission_id, assigned_date, selected_tech_stack, completed, completed_at, is_correct',
            )
            .eq('user_id', user.id)
            .eq('assigned_date', today)
            .order('assigned_date', ascending: false)
            .limit(1)
            .maybeSingle();

        row = row == null ? null : Map<String, dynamic>.from(row);

        if (row == null) {
          final assigned = await _client.rpc(
            'assign_daily_mission',
            params: {
              'p_requested_stack': techStack?.trim().isEmpty ?? true
                  ? null
                  : techStack!.trim(),
            },
          );

          if (assigned is Map) {
            row = Map<String, dynamic>.from(assigned);
          }
        }

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
              ...row,
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
    try {
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
    } catch (error) {
      if (!_isRouteMissingError(error)) rethrow;

      final data = await _request(
        'POST',
        '/missions',
        includeFounderDevice: true,
        body: {
          'title': title,
          'type': 'oneword',
          'techStack': techStack,
          'question': description,
          'pointsReward': pointsReward,
          'publishDate': publishDate,
          'isActive': true,
        },
      ) as Map;

      return _mapMissionToLegacyChallengeShape(Map<String, dynamic>.from(data));
    }
  }

  Future<List<Map<String, dynamic>>> getAdminChallenges() async {
    try {
      final data = await _request(
        'GET',
        '/challenges',
        includeFounderDevice: true,
        queryParameters: {'includeInactive': true},
      ) as List<dynamic>;
      return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (error) {
      if (!_isRouteMissingError(error)) rethrow;

      final data = await _request(
        'GET',
        '/missions',
        includeFounderDevice: true,
        queryParameters: {'includeInactive': true},
      ) as List<dynamic>;

      return data
          .map(
            (item) => _mapMissionToLegacyChallengeShape(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }
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
    try {
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
    } catch (error) {
      if (!_isRouteMissingError(error)) rethrow;

      final data = await _request(
        'PATCH',
        '/missions/$challengeId',
        includeFounderDevice: true,
        body: {
          'title': title,
          'type': 'oneword',
          'techStack': techStack,
          'question': description,
          'pointsReward': pointsReward,
          'isActive': isActive,
        },
      ) as Map;

      return _mapMissionToLegacyChallengeShape(Map<String, dynamic>.from(data));
    }
  }

  Future<Map<String, dynamic>> deactivateChallenge(String challengeId) async {
    try {
      final data = await _request(
        'POST',
        '/challenges/$challengeId/deactivate',
        includeFounderDevice: true,
      ) as Map;
      return Map<String, dynamic>.from(data);
    } catch (error) {
      if (!_isRouteMissingError(error)) rethrow;

      final data = await _request(
        'POST',
        '/missions/$challengeId/deactivate',
        includeFounderDevice: true,
      ) as Map;
      return _mapMissionToLegacyChallengeShape(Map<String, dynamic>.from(data));
    }
  }

  Map<String, dynamic> _mapMissionToLegacyChallengeShape(
    Map<String, dynamic> mission,
  ) {
    final type = mission['type']?.toString() ?? 'oneword';
    final difficulty = switch (type) {
      'coding' => 'hard',
      'mcq' => 'medium',
      _ => 'easy',
    };

    return {
      'id': mission['id'],
      'title': mission['title'] ?? '',
      'description': mission['question'] ?? '',
      'difficulty': difficulty,
      'tech_stack': mission['tech_stack'] ?? '',
      'points_reward': mission['points_reward'] ?? 0,
      'is_active': mission['is_active'] ?? true,
      'publish_date': mission['publish_date'],
      'type': mission['type'],
      'link': mission['link'],
      'options': mission['options'],
      'correct_answer': mission['correct_answer'],
    };
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
    try {
      final data = await _request(
        'GET',
        '/missions',
        includeFounderDevice: true,
        queryParameters: {'includeInactive': true},
      ) as List<dynamic>;

      return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (error) {
      if (!_isRouteMissingError(error)) rethrow;

      final data = await _client
          .from('missions')
          .select(
            'id, title, type, tech_stack, question, options, correct_answer, link, points_reward, publish_date, is_active, created_by, created_at, updated_at',
          )
          .order('publish_date', ascending: false)
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
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
    try {
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
    } catch (error) {
      if (!_isRouteMissingError(error)) rethrow;

      final data = await _client
          .from('missions')
          .insert({
            'title': title.trim(),
            'type': type.trim(),
            'tech_stack': techStack.trim(),
            'question': question.trim(),
            'options': options,
            'correct_answer': correctAnswer?.trim(),
            'link': link?.trim(),
            'points_reward': pointsReward,
            'publish_date': publishDate,
            'is_active': isActive,
            'created_by': _client.auth.currentUser?.id,
          })
          .select(
            'id, title, type, tech_stack, question, options, correct_answer, link, points_reward, publish_date, is_active, created_by, created_at, updated_at',
          )
          .single();

      return Map<String, dynamic>.from(data);
    }
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
    try {
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
    } catch (error) {
      if (!_isRouteMissingError(error)) rethrow;

      final data = await _client
          .from('missions')
          .update({
            if (title != null) 'title': title.trim(),
            if (type != null) 'type': type.trim(),
            if (techStack != null) 'tech_stack': techStack.trim(),
            if (question != null) 'question': question.trim(),
            if (options != null) 'options': options,
            if (correctAnswer != null) 'correct_answer': correctAnswer.trim(),
            if (link != null) 'link': link.trim(),
            if (pointsReward != null) 'points_reward': pointsReward,
            if (publishDate != null) 'publish_date': publishDate,
            if (isActive != null) 'is_active': isActive,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', missionId)
          .select(
            'id, title, type, tech_stack, question, options, correct_answer, link, points_reward, publish_date, is_active, created_by, created_at, updated_at',
          )
          .single();

      return Map<String, dynamic>.from(data);
    }
  }

  Future<Map<String, dynamic>> deactivateMission(String missionId) async {
    try {
      final data = await _request(
        'POST',
        '/missions/$missionId/deactivate',
        includeFounderDevice: true,
      ) as Map;

      return Map<String, dynamic>.from(data);
    } catch (error) {
      if (!_isRouteMissingError(error)) rethrow;

      final data = await _client
          .from('missions')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', missionId)
          .select(
            'id, title, type, tech_stack, question, options, correct_answer, link, points_reward, publish_date, is_active, created_by, created_at, updated_at',
          )
          .single();

      return Map<String, dynamic>.from(data);
    }
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
    } catch (error) {
      if (_isRouteMissingError(error)) {
        final user = _client.auth.currentUser;
        final email = user?.email?.trim().toLowerCase() ?? '';
        if (email == 'businessrexxon@gmail.com') {
          return true;
        }

        if (user != null) {
          try {
            final row = await _client
                .from('users')
                .select('is_admin')
                .eq('id', user.id)
                .maybeSingle();
            return row?['is_admin'] == true;
          } catch (_) {
            return false;
          }
        }
      }
      return false;
    }
  }

  String cleanErrorText(Object error) => _cleanErrorText(error);

  Future<Map<String, dynamic>?> _resolveWeeklyFreeChallengeFallback({
    String? techStack,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final userRow = await _client
        .from('users')
        .select('stack')
        .eq('id', user.id)
        .maybeSingle();

    final requestedCandidates = <String>{};
    if (techStack != null && techStack.trim().isNotEmpty) {
      requestedCandidates.addAll(_stackCandidates(techStack));
      requestedCandidates.add(techStack.trim().toLowerCase());
    }

    final rawStacks = (userRow?['stack'] as List?) ?? const [];
    for (final item in rawStacks) {
      final value = item.toString().trim();
      if (value.isEmpty) continue;
      requestedCandidates.add(value.toLowerCase());
      requestedCandidates.addAll(_stackCandidates(value));
    }
    requestedCandidates.add('general');

    // Fetch from challenges table for weekly tasks
    final challengeRows = await _client
        .from('challenges')
        .select(
          'id, title, description, difficulty, tech_stack, points_reward, publish_date, is_active',
        )
        .eq('is_active', true)
        .order('publish_date', ascending: false)
        .limit(20);

    if (challengeRows is! List || challengeRows.isEmpty) {
      return null;
    }

    Map<String, dynamic>? matchedChallenge;
    for (final row in challengeRows) {
      final challenge = Map<String, dynamic>.from(row as Map);
      final challengeStack = challenge['tech_stack']?.toString().trim() ?? '';
      final challengeCandidates = <String>{
        challengeStack.toLowerCase(),
        ..._stackCandidates(challengeStack),
      }..remove('');

      if (challengeCandidates.any(requestedCandidates.contains)) {
        matchedChallenge = challenge;
        break;
      }
    }

    matchedChallenge ??= challengeRows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .firstWhere(
          (c) =>
              (c['tech_stack']?.toString().trim().toLowerCase() ?? '') ==
              'general',
          orElse: () => Map<String, dynamic>.from(challengeRows.first as Map),
        );

    return {
      'id': '',
      'challenge_id': matchedChallenge['id'],
      'assigned_date': DateTime.now().toIso8601String().split('T').first,
      'selected_tech_stack': requestedCandidates.first,
      'completed': false,
      'completed_at': null,
      'is_correct': false,
      'challenge': matchedChallenge,
    };
  }

  Future<DailyChallengeModel?> getWeeklyFreeChallenge({String? techStack}) async {
    try {
      final data = Map<String, dynamic>.from(
        await _request(
          'GET',
          '/missions/weekly-free',
          queryParameters: techStack == null ? null : {'techStack': techStack},
        ) as Map,
      );
      return DailyChallengeModel.fromJson(data);
    } catch (error) {
      if (!_isRouteMissingError(error)) rethrow;
      
      final data = await _resolveWeeklyFreeChallengeFallback(techStack: techStack);
      if (data == null) return null;
      return DailyChallengeModel.fromJson(data);
    }
  }

  Future<Map<String, dynamic>> submitWeeklyFreeChallenge({
    required String submissionText,
    String submissionLink = '',
  }) async {
    try {
      final data = await _request(
        'POST',
        '/missions/weekly-free/submit',
        body: {
          'submissionText': submissionText,
          'submissionLink': submissionLink,
        },
      ) as Map;
      return Map<String, dynamic>.from(data);
    } catch (error) {
      if (!_isRouteMissingError(error)) rethrow;
      
      // Use the daily submission as a fallback
      return completeDailyChallenge(
        submissionText: submissionText,
        submissionLink: submissionLink,
      );
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
        rethrow;
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
