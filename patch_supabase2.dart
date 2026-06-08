import 'dart:io';

void main() {
  final file = File('lib/services/supabase_service.dart');
  var content = file.readAsStringSync();
  
  final injection = '''
  Future<String?> findRandomMatch({
    required String userId,
    required String category,
    required String mode,
  }) async {
    final response = await _client.rpc('find_match', params: {
      'p_user_id': userId,
      'p_category': category,
      'p_mode': mode,
    });
    if (response != null) {
      return response.toString();
    }
    return null;
  }

  Future<void> leaveMatchmakingPool(String userId) async {
    await _client.from('matchmaking_pool').delete().eq('user_id', userId);
  }

  RealtimeChannel listenToLiveDuels(
      String userId, void Function(Map<String, dynamic> duel) onMatchFound) {
    return _client
        .channel('public:live_duels:matchmaking:\$userId')
        .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'live_duels',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'player2_id', // Since the RPC puts the pool user in player1_id, wait no, RPC does: player1_id = v_opponent_id, player2_id = p_user_id. So the waiting person is player1_id.
              // We can't do an OR filter on Realtime easily, so we just listen to ALL inserts and filter client-side. Or we listen to player1_id = my_id. 
              // Wait, in RPC: The person IN THE POOL (waiting) is v_opponent_id (player1). The person who searched and found them is p_user_id (player2).
              // So the waiter should listen for player1_id = userId.
              value: userId,
            ),
            callback: (payload) {
              onMatchFound(payload.newRecord);
            })
        .subscribe();
  }
}
''';

  content = content.replaceFirst(
    "RealtimeChannel listenToDuelRequestStatus(", 
    injection.replaceAll("}", "") + "\n\n  RealtimeChannel listenToDuelRequestStatus("
  );
  
  // Actually, wait, let's just do a simpler replace. I'll replace the closing brace of the class.
  // The class ends with: `  }` then `}`
  content = content.trimRight();
  if (content.endsWith('}')) {
    content = content.substring(0, content.length - 1); // remove last brace
    content += '''
  Future<String?> findRandomMatch({
    required String userId,
    required String category,
    required String mode,
  }) async {
    final response = await _client.rpc('find_match', params: {
      'p_user_id': userId,
      'p_category': category,
      'p_mode': mode,
    });
    if (response != null) {
      return response.toString();
    }
    return null;
  }

  Future<void> leaveMatchmakingPool(String userId) async {
    await _client.from('matchmaking_pool').delete().eq('user_id', userId);
  }

  RealtimeChannel listenToLiveDuels(
      String userId, void Function(Map<String, dynamic> duel) onMatchFound) {
    return _client
        .channel('public:live_duels:matchmaking:\$userId')
        .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'live_duels',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'player1_id',
              value: userId,
            ),
            callback: (payload) {
              onMatchFound(payload.newRecord);
            })
        .subscribe();
  }
}
''';
  }

  file.writeAsStringSync(content);
}
