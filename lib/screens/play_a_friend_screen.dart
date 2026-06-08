import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'waiting_for_opponent_screen.dart';
import '../services/supabase_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../providers/users_provider.dart';
import '../widgets/profile_card.dart';
import 'duel_screen.dart';

class PlayAFriendScreen extends StatefulWidget {
  final String category;
  final String mode;
  final Color color;

  const PlayAFriendScreen({
    super.key,
    required this.category,
    required this.mode,
    required this.color,
  });

  @override
  State<PlayAFriendScreen> createState() => _PlayAFriendScreenState();
}

class _PlayAFriendScreenState extends State<PlayAFriendScreen> {
  bool _isLiveDuel = true;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final usersP = context.read<UsersProvider>();
      if (usersP.users.isEmpty && !usersP.isLoading) {
        usersP.fetchUsers(query: _query);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() {
      _query = value.trim();
    });
    context.read<UsersProvider>().fetchUsers(query: _query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Play A Friend',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invite link copied to clipboard!')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Play via Link',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: _onSearch,
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search for the friend',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.5), size: 20),
                  filled: true,
                  fillColor: Colors.transparent,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: widget.color.withValues(alpha: 0.8)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),

              const SizedBox(height: 32),

              // Mode of Duel Title
              Text(
                'MODE OF DUEL',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white60,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),

              // Mode Toggles
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isLiveDuel = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: _isLiveDuel ? Colors.green.withValues(alpha: 0.1) : const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isLiveDuel ? Colors.greenAccent : Colors.white.withValues(alpha: 0.1),
                            width: 1.5,
                          ),
                          boxShadow: _isLiveDuel ? [
                            BoxShadow(
                              color: Colors.greenAccent.withValues(alpha: 0.5),
                              offset: const Offset(0, 4),
                            )
                          ] : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'LIVE DUELS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _isLiveDuel ? Colors.greenAccent : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isLiveDuel = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: !_isLiveDuel ? widget.color.withValues(alpha: 0.1) : const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !_isLiveDuel ? widget.color : Colors.white.withValues(alpha: 0.1),
                            width: 1.5,
                          ),
                          boxShadow: !_isLiveDuel ? [
                            BoxShadow(
                              color: widget.color.withValues(alpha: 0.5),
                              offset: const Offset(0, 4),
                            )
                          ] : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'ASYNC DUELS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: !_isLiveDuel ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Center(
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1E1E1E),
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text(
                          'How Duels Work',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.flash_on_rounded, color: Colors.greenAccent, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Live Duels (Sync)',
                                  style: GoogleFonts.plusJakartaSans(color: Colors.greenAccent, fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Compete live when both users are online. Answer questions simultaneously and race to the finish!',
                              style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Icon(Icons.schedule_rounded, color: widget.color, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Async Duels',
                                  style: GoogleFonts.plusJakartaSans(color: widget.color, fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Challenge a friend even if they are offline. You play first to set a score. When they return, they will get the exact same questions and try to beat your score!',
                              style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Understood',
                              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text(
                    'What are these Duels?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.white38,
                      decoration: TextDecoration.underline,
                      decorationStyle: TextDecorationStyle.dashed,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'ONLINE FRIENDS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white60,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: Consumer<UsersProvider>(
                  builder: (context, usersP, _) {
                    final allUsers = usersP.users;
                    final users = _isLiveDuel 
                        ? allUsers.where((u) => u.isFollowing).toList()
                        : allUsers;

                    if (usersP.isLoading && users.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white24),
                      );
                    }
                    if (users.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isLiveDuel ? Icons.people_outline_rounded : Icons.person_search_rounded, 
                              size: 64, 
                              color: widget.color.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isLiveDuel 
                                  ? 'No online friends found' 
                                  : (_query.isEmpty ? 'No friends found' : 'No users match your search'),
                              style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: users.length,
                      itemBuilder: (context, i) {
                        final user = users[i];
                        // Using a dark theme adaptation for ProfileCard to ensure visibility
                        return Theme(
                          data: Theme.of(context).copyWith(
                            scaffoldBackgroundColor: const Color(0xFF141414),
                            textTheme: Theme.of(context).textTheme.apply(
                              bodyColor: Colors.white,
                              displayColor: Colors.white,
                            ),
                          ),
                          child: ProfileCard(
                            user: user,
                            trailing: ElevatedButton(
                              onPressed: () async {
                                try {
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
                                    final newMatchId = await SupabaseService.instance.createArenaMatch(widget.mode, opponentId: user.id);
                                    if (context.mounted) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DuelScreen(
                                            category: widget.category,
                                            mode: widget.mode,
                                            matchId: newMatchId,
                                            isPlayer1: true,
                                            opponent: user,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to start challenge: $e'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.color.withValues(alpha: 0.15),
                                foregroundColor: widget.color,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                minimumSize: const Size(0, 32),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                side: BorderSide(color: widget.color.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                _isLiveDuel ? 'Invite' : 'Challenge',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                              ),
                            ),
                            onTap: () async {
                                try {
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
                                    final newMatchId = await SupabaseService.instance.createArenaMatch(widget.mode, opponentId: user.id);
                                    if (context.mounted) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DuelScreen(
                                            category: widget.category,
                                            mode: widget.mode,
                                            matchId: newMatchId,
                                            isPlayer1: true,
                                            opponent: user,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to start challenge: $e'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
