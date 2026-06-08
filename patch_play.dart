import 'dart:io';

void main() {
  final file = File('lib/screens/play_a_friend_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "import 'package:google_fonts/google_fonts.dart';",
    "import 'package:google_fonts/google_fonts.dart';\nimport 'waiting_for_opponent_screen.dart';\nimport '../services/supabase_service.dart';\nimport '../providers/auth_provider.dart';"
  );
  
  final oldAction = '''
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DuelScreen(
                                      category: widget.category,
                                      mode: _isLiveDuel ? 'Live Duel' : 'Async Duel',
                                      opponent: user,
                                    ),
                                  ),
                                );
                              },
''';

  final newAction = '''
                              onPressed: () async {
                                if (_isLiveDuel) {
                                  final me = context.read<AuthProvider>().currentUserOrNull;
                                  if (me != null) {
                                    final requestId = await SupabaseService.instance.sendDuelRequest(
                                      senderId: me.id,
                                      receiverId: user.id,
                                      category: widget.category,
                                      mode: 'Live Duel',
                                    );
                                    if (context.mounted) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => WaitingForOpponentScreen(
                                            requestId: requestId,
                                            category: widget.category,
                                            mode: 'Live Duel',
                                            opponent: user,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DuelScreen(
                                        category: widget.category,
                                        mode: 'Async Duel',
                                        opponent: user,
                                      ),
                                    ),
                                  );
                                }
                              },
''';

  content = content.replaceFirst(oldAction, newAction);

  final oldTap = '''
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DuelScreen(
                                    category: widget.category,
                                    mode: _isLiveDuel ? 'Live Duel' : 'Async Duel',
                                    opponent: user,
                                  ),
                                ),
                              );
                            },
''';

  final newTap = '''
                            onTap: () async {
                                if (_isLiveDuel) {
                                  final me = context.read<AuthProvider>().currentUserOrNull;
                                  if (me != null) {
                                    final requestId = await SupabaseService.instance.sendDuelRequest(
                                      senderId: me.id,
                                      receiverId: user.id,
                                      category: widget.category,
                                      mode: 'Live Duel',
                                    );
                                    if (context.mounted) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => WaitingForOpponentScreen(
                                            requestId: requestId,
                                            category: widget.category,
                                            mode: 'Live Duel',
                                            opponent: user,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DuelScreen(
                                        category: widget.category,
                                        mode: 'Async Duel',
                                        opponent: user,
                                      ),
                                    ),
                                  );
                                }
                            },
''';
  
  content = content.replaceFirst(oldTap, newTap);
  
  file.writeAsStringSync(content);
}
