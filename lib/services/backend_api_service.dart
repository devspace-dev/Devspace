import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/aura_summary_model.dart';
import '../models/daily_challenge_model.dart';
import '../models/event_access_model.dart';
import '../models/post_model.dart';
import 'founder_device_service.dart';
import '../utils/runtime_config.dart';

class BackendApiService {
  BackendApiService._internal();
  static final BackendApiService instance = BackendApiService._internal();
  static const Duration _requestTimeout = Duration(seconds: 20);

  SupabaseClient get _client => Supabase.instance.client;

  bool _isRouteMissingError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('backend route not found') ||
        message.contains('status 404');
  }

  String cleanErrorText(Object error) {
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
    final supabaseAnonKey = RuntimeConfig.instance.supabaseAnonKey;
    if (supabaseAnonKey.isEmpty) {
      throw StateError(
        'Missing Supabase runtime config. Add SUPABASE_ANON_KEY with --dart-define or .env.local.json before using backend APIs.',
      );
    }

    final token = _client.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('No authenticated session is available. Sign in again.');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'apikey': supabaseAnonKey,
    };

    if (includeFounderDevice) {
      headers['X-Device-Id'] = await FounderDeviceService.instance.getDeviceId();
    }

    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? queryParameters]) {
    final supabaseUrl = RuntimeConfig.instance.supabaseUrl;
    if (supabaseUrl.isEmpty) {
      throw StateError(
        'Missing Supabase runtime config. Add SUPABASE_URL with --dart-define or .env.local.json before using backend APIs.',
      );
    }

    final base = Uri.parse(supabaseUrl);
    if (base.scheme != 'https') {
      throw StateError('Backend requests must use HTTPS in production-ready builds.');
    }

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

    try {
      late final http.Response response;
      switch (method) {
        case 'GET':
          response = await http
              .get(uri, headers: headers)
              .timeout(_requestTimeout);
          break;
        case 'POST':
          response = await http
              .post(
                uri,
                headers: headers,
                body: jsonEncode(body ?? const {}),
              )
              .timeout(_requestTimeout);
          break;
        case 'DELETE':
          response = await http
              .delete(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(_requestTimeout);
          break;
        case 'PATCH':
          response = await http
              .patch(
                uri,
                headers: headers,
                body: jsonEncode(body ?? const {}),
              )
              .timeout(_requestTimeout);
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
    } on SocketException {
      throw StateError(
        'No internet connection. Check your network and try again.',
      );
    } on TimeoutException {
      throw StateError(
        'The request took too long. Please retry on a stronger connection.',
      );
    }
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
            .select('id, title, description, required_aura, link, type, banner_url, date, end_date, location, organizer')
            .or('end_date.is.null,end_date.gte.${DateTime.now().toUtc().toIso8601String()}')
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
                bannerUrl: event['banner_url']?.toString(),
                date: event['date']?.toString(),
                location: event['location']?.toString(),
                organizer: event['organizer']?.toString(),
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
    String? bannerUrl,
    String? date,
    String? location,
    String? organizer,
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
          'bannerUrl': bannerUrl,
          'date': date,
          'location': location,
          'organizer': organizer,
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
            'banner_url': bannerUrl?.trim(),
            'date': date?.trim(),
            'location': location?.trim(),
            'organizer': organizer?.trim(),
            'is_active': true,
            'created_by': _client.auth.currentUser?.id,
          })
          .select(
            'id, title, description, required_aura, link, type, banner_url, date, location, organizer, is_active, created_by, created_at, updated_at',
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
            'id, title, description, required_aura, link, type, banner_url, date, location, organizer, is_active, created_by, created_at, updated_at',
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
    String? bannerUrl,
    String? date,
    String? location,
    String? organizer,
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
          'bannerUrl': bannerUrl,
          'date': date,
          'location': location,
          'organizer': organizer,
        },
      ) as Map;

      return Map<String, dynamic>.from(data);
    } catch (error) {
      debugPrint('updateEvent error for event $eventId: $error');
      if (!_isRouteMissingError(error)) rethrow;

      debugPrint('updateEvent falling back to direct DB update for event $eventId');
      final data = await _client
          .from('events')
          .update({
            'title': title.trim(),
            'description': description.trim(),
            'required_aura': requiredAura,
            'link': link.trim(),
            'type': type.trim(),
            'banner_url': bannerUrl?.trim(),
            'date': date?.trim(),
            'location': location?.trim(),
            'organizer': organizer?.trim(),
            'is_active': isActive,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', eventId)
          .select(
            'id, title, description, required_aura, link, type, banner_url, date, location, organizer, is_active, created_by, created_at, updated_at',
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
      final data = await _request(
        'GET',
        '/missions/daily',
        queryParameters: techStack == null ? null : {'techStack': techStack},
      );
      
      if (data == null) return null; // No daily mission found
      return DailyChallengeModel.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (error) {
      if (!_isRouteMissingError(error)) {
        rethrow;
      }

      // Fallback logic if API route is missing
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final today = DateTime.now().toIso8601String().split('T').first;
      
      // 1. Try to find an existing assignment for today in user_missions
      Map<String, dynamic>? row = await _client
          .from('user_missions')
          .select(
            'id, mission_id, assigned_date, selected_tech_stack, completed, completed_at, is_correct',
          )
          .eq('user_id', user.id)
          .eq('assigned_date', today)
          .maybeSingle();

      row = row == null ? null : Map<String, dynamic>.from(row);

      // 2. If no assignment, try to assign one via RPC
      if (row == null) {
        try {
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
        } catch (e) {
          debugPrint('RPC assign_daily_mission failed: $e');
        }
      }

      // 3. If we have an assignment (new or existing), fetch the mission details
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

      // 4. If missions table didn't work, try legacy challenges table
      try {
        final userChallengeRow = await _client
            .from('user_challenges')
            .select(
              'id, challenge_id, assigned_date, selected_tech_stack, completed, completed_at',
            )
            .eq('user_id', user.id)
            .eq('assigned_date', today)
            .maybeSingle();

        if (userChallengeRow != null) {
          final challenge = await _client
              .from('challenges')
              .select('id, title, description, difficulty, tech_stack, points_reward')
              .eq('id', userChallengeRow['challenge_id'])
              .maybeSingle();

          if (challenge != null) {
            return DailyChallengeModel.fromJson({
              ...Map<String, dynamic>.from(userChallengeRow),
              'challenge': challenge,
            });
          }
        }
      } catch (e) {
        debugPrint('Fallback to user_challenges failed: $e');
      }

      return null;
    }
  }

  Future<List<DailyChallengeModel>> getWeeklyFreeChallenge({String? techStack}) async {
    try {
      final data = await _request(
        'GET',
        '/missions/weekly-free',
        queryParameters: techStack == null ? null : {'techStack': techStack},
      );
      
      if (data is List) {
        return data.map((item) => DailyChallengeModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      } else if (data != null) {
        return [DailyChallengeModel.fromJson(Map<String, dynamic>.from(data as Map))];
      }
      return const [];
    } catch (error) {
      if (!_isRouteMissingError(error)) rethrow;
      
      // Fallback: Check both missions (weekly-free type) and challenges table
      final List<DailyChallengeModel> results = [];
      
      // Try missions table first
      try {
        final missionRows = await _resolveWeeklyFreeChallengeFallback(techStack: techStack);
        results.addAll(missionRows);
      } catch (e) {
        debugPrint('Weekly missions fallback failed: $e');
      }
      
      // If missions empty, try challenges table (the one populated by SEED_WEEKLY_CHALLENGES.sql)
      if (results.isEmpty) {
        try {
          final uid = _client.auth.currentUser?.id;
          final query = _client.from('challenges').select().eq('is_active', true);
          
          if (techStack != null && techStack.trim().isNotEmpty && techStack.toLowerCase() != 'general') {
            query.ilike('tech_stack', '%${techStack.trim()}%');
          }
          
          final challengeRows = await query.order('publish_date', ascending: false).limit(15);
          
          if (challengeRows is List && challengeRows.isNotEmpty) {
            List<dynamic> userStatus = [];
            if (uid != null) {
              userStatus = await _client
                  .from('user_challenges')
                  .select('challenge_id, completed, completed_at, is_correct')
                  .eq('user_id', uid);
            }

            final statusMap = {
              for (final s in userStatus) s['challenge_id'].toString(): s
            };

            for (final row in challengeRows) {
              final id = row['id'].toString();
              final status = statusMap[id];

              results.add(DailyChallengeModel.fromJson({
                'id': status?['id'] ?? 'weekly_$id',
                'challenge_id': id,
                'assigned_date': row['publish_date'],
                'completed': status?['completed'] == true,
                'completed_at': status?['completed_at'],
                'is_correct': status?['is_correct'] == true,
                'challenge': row,
              }));
            }
          }
        } catch (e) {
          debugPrint('Weekly challenges fallback failed: $e');
        }
      }
      
      return results;
    }
  }

  Future<Map<String, dynamic>> submitWeeklyFreeChallenge({
    required String submissionText,
    String submissionLink = '',
    String? challengeId,
  }) async {
    try {
      final data = await _request(
        'POST',
        '/missions/weekly-free/submit',
        body: {
          'submissionText': submissionText,
          'submissionLink': submissionLink,
          if (challengeId != null) 'challengeId': challengeId,
        },
      ) as Map;
      return Map<String, dynamic>.from(data);
    } catch (error) {
      if (!_isRouteMissingError(error)) rethrow;
      
      final uid = _client.auth.currentUser?.id;
      if (uid == null) throw StateError('No authenticated session.');

      // Fallback 1: If it's a specific challenge from the 'challenges' table
      if (challengeId != null && challengeId.startsWith('weekly_')) {
        try {
          final realId = challengeId.replaceFirst('weekly_', '');
          final challenge = await _client
              .from('challenges')
              .select('correct_answer, points_reward')
              .eq('id', realId)
              .single();
          
          final isCorrect = (challenge['correct_answer']?.toString() ?? '').trim() == submissionText.trim();
          final points = isCorrect ? ((challenge['points_reward'] as num?)?.toInt() ?? 20) : 5;

          await _client.from('user_challenges').upsert({
            'user_id': uid,
            'challenge_id': realId,
            'completed': true,
            'completed_at': DateTime.now().toUtc().toIso8601String(),
            'is_correct': isCorrect,
            'points_awarded': points,
          }, onConflict: 'user_id, challenge_id');

          // Award Aura
          await _client.rpc('award_aura', params: {
            'p_user_id': uid,
            'p_action': isCorrect ? 'challenge_solved' : 'challenge_attempted',
            'p_points': points,
            'p_reference_type': 'challenge',
            'p_reference_id': realId,
          });

          return {'success': true, 'is_correct': isCorrect, 'points': points};
        } catch (e) {
          debugPrint('Weekly challenges fallback failed: $e');
        }
      }

      // Fallback 2: Try legacy RPCs
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

  Future<bool> hasFounderAccess() async {
    try {
      final data = await _request(
        'GET',
        '/admin/founder-access',
        includeFounderDevice: true,
      );
      if (data is Map) return data['hasAccess'] == true;
      return data == true;
    } catch (_) {
      try {
        final user = _client.auth.currentUser;
        if (user == null) return false;
        
        final deviceId = await FounderDeviceService.instance.getDeviceId();
        final dbRow = await _client
            .from('founder_devices')
            .select('is_active')
            .eq('device_id', deviceId)
            .maybeSingle();

        return dbRow?['is_active'] == true;
      } catch (_) {
        return false;
      }
    }
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
            'id, title, description, question, tech_stack, options, correct_answer, type, is_active, points_reward, created_by, publish_date, created_at',
          )
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
  }

  Future<Map<String, dynamic>> createMission({
    required String title,
    required String type,
    String? techStack,
    required String question,
    required List<String> options,
    required String publishDate,
    required int pointsReward,
    required String correctAnswer,
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
          'publishDate': publishDate,
          'pointsReward': pointsReward,
          'correctAnswer': correctAnswer,
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
            'tech_stack': techStack?.trim(),
            'question': question.trim(),
            'options': options.map((e) => e.trim()).toList(),
            'publish_date': publishDate.trim(),
            'points_reward': pointsReward,
            'correct_answer': correctAnswer.trim(),
            'is_active': true,
            'created_by': _client.auth.currentUser?.id,
          })
          .select(
            'id, title, description, question, tech_stack, options, correct_answer, type, is_active, points_reward, created_by, publish_date, created_at',
          )
          .single();

      return Map<String, dynamic>.from(data);
    }
  }

  Future<List<Map<String, dynamic>>> bulkCreateMissions(
      List<Map<String, dynamic>> missions) async {
    try {
      final data = await _request(
        'POST',
        '/missions/bulk',
        includeFounderDevice: true,
        body: {'missions': missions},
      ) as List<dynamic>;

      return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (error) {
      if (!_isRouteMissingError(error)) rethrow;

      final inserts = missions.map((m) {
        return {
          'title': m['title']?.toString().trim() ?? '',
          'type': m['type']?.toString().trim() ?? 'mcq',
          'tech_stack': m['techStack']?.toString().trim(),
          'question': m['question']?.toString().trim() ?? '',
          'options': (m['options'] as List<dynamic>?)
                  ?.map((e) => e.toString().trim())
                  .toList() ??
              const [],
          'publish_date': m['publishDate']?.toString().trim() ??
              DateTime.now().toIso8601String().split('T')[0],
          'points_reward': (m['pointsReward'] as num?)?.toInt() ?? 20,
          'correct_answer': m['correctAnswer']?.toString().trim() ?? '',
          'is_active': true,
          'created_by': _client.auth.currentUser?.id,
        };
      }).toList();

      final data = await _client
          .from('missions')
          .insert(inserts)
          .select(
            'id, title, description, question, tech_stack, options, correct_answer, type, is_active, points_reward, created_by, publish_date, created_at',
          );

      return (data as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
  }

  Future<Map<String, dynamic>> updateMission({
    required String missionId,
    required String title,
    required String type,
    String? techStack,
    required String question,
    required List<String> options,
    required String publishDate,
    required int pointsReward,
    required String correctAnswer,
    required bool isActive,
  }) async {
    try {
      final data = await _request(
        'PATCH',
        '/missions/$missionId',
        includeFounderDevice: true,
        body: {
          'title': title,
          'type': type,
          'techStack': techStack,
          'question': question,
          'options': options,
          'publishDate': publishDate,
          'pointsReward': pointsReward,
          'correctAnswer': correctAnswer,
          'isActive': isActive,
        },
      ) as Map;

      return Map<String, dynamic>.from(data);
    } catch (error) {
      if (!_isRouteMissingError(error)) rethrow;

      final data = await _client
          .from('missions')
          .update({
            'title': title.trim(),
            'type': type.trim(),
            'tech_stack': techStack?.trim(),
            'question': question.trim(),
            'options': options.map((e) => e.trim()).toList(),
            'publish_date': publishDate.trim(),
            'points_reward': pointsReward,
            'correct_answer': correctAnswer.trim(),
            'is_active': isActive,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', missionId)
          .select(
            'id, title, description, question, tech_stack, options, correct_answer, type, is_active, points_reward, created_by, publish_date, created_at',
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
            'id, title, description, question, tech_stack, options, correct_answer, type, is_active, points_reward, created_by, publish_date, created_at',
          )
          .single();

      return Map<String, dynamic>.from(data);
    }
  }

  Future<List<DailyChallengeModel>> _resolveWeeklyFreeChallengeFallback({
    String? techStack,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return const [];

    final today = DateTime.now().toIso8601String().split('T').first;
    try {
      final missionRows = await _client
          .from('missions')
          .select(
            'id, title, type, tech_stack, question, options, correct_answer, link, points_reward, publish_date, is_active',
          )
          .eq('is_active', true)
          .eq('type', 'weekly-free')
          .gte('publish_date', today)
          .order('publish_date', ascending: true);

      if (missionRows is! List || missionRows.isEmpty) {
        return const [];
      }

      return missionRows.map((row) {
        final mission = Map<String, dynamic>.from(row as Map);
        return DailyChallengeModel.fromJson({
          'id': '',
          'mission_id': mission['id'],
          'assigned_date': today,
          'selected_tech_stack': techStack,
          'completed': false,
          'completed_at': null,
          'is_correct': false,
          'mission': mission,
        });
      }).toList();
    } catch (_) {
      return const [];
    }
  }
}
