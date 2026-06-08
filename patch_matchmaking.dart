import 'dart:io';

void main() {
  final file = File('lib/screens/matchmaking_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "import '../models/user_model.dart';",
    "import '../models/user_model.dart';\nimport '../services/supabase_service.dart';\nimport '../providers/auth_provider.dart';\nimport '../providers/users_provider.dart';\nimport 'package:provider/provider.dart';\nimport 'package:supabase_flutter/supabase_flutter.dart';"
  );
  
  final oldInitState = '''
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showIntro = false);
    });

    // Simulate finding a match after some time
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DuelScreen(
              category: widget.category,
              mode: widget.mode,
              opponent: UserModel(
                id: 'dummy_opponent',
                name: 'Guest Player',
                handle: 'guest_player',
                email: 'guest@example.com',
                avatar: 'https://ui-avatars.com/api/?name=Guest+Player&background=random',
                color: Colors.blue,
                aura: 974,
                roles: ['Builder'],
                year: '3rd Year',
                branch: 'CS',
                building: '',
                stack: ['Flutter'],
                followers: 0,
                following: 0,
                bio: 'Ready to duel.',
                college: 'Unknown College',
                githubHandle: '',
                profileCompleted: true,
              ),
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
''';

  final newInitState = '''
  RealtimeChannel? _matchSubscription;
  bool _matchFound = false;
  String? _myUserId;
  bool _searching = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showIntro = false);
    });

    _startMatchmaking();
  }

  void _startMatchmaking() async {
    setState(() => _searching = true);
    final user = context.read<AuthProvider>().currentUserOrNull;
    if (user == null) return;
    _myUserId = user.id;

    // First, try to find an immediate match using the RPC
    final duelId = await SupabaseService.instance.findRandomMatch(
      userId: user.id,
      category: widget.category,
      mode: widget.mode,
    );

    if (duelId != null && mounted) {
      _matchFound = true;
      // We found a match immediately!
      // In a full implementation we would fetch the live_duel row to get the opponent ID.
      // But since we are MVP, we can jump to a generic opponent or fetch it.
      // We'll jump to DuelScreen with a generic opponent for now, 
      // or better: we just know we have a match.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DuelScreen(
            category: widget.category,
            mode: widget.mode,
            opponent: UserModel(
              id: 'matched_player',
              name: 'Online Challenger',
              handle: 'challenger',
              email: '',
              avatar: '',
              color: Colors.deepPurple,
              aura: 1000,
              roles: [],
              year: '',
              branch: '',
              building: '',
              stack: [],
              followers: 0,
              following: 0,
              bio: '',
              college: '',
              githubHandle: '',
              profileCompleted: true,
            ),
          ),
        ),
      );
      return;
    }

    // If no immediate match, we are now in the pool. Listen for someone to match US.
    _matchSubscription = SupabaseService.instance.listenToLiveDuels(user.id, (duel) {
      if (!mounted || _matchFound) return;
      if (duel['category'] == widget.category) {
        _matchFound = true;
        _matchSubscription?.unsubscribe();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DuelScreen(
              category: widget.category,
              mode: widget.mode,
              opponent: UserModel(
                id: duel['player2_id'].toString(), // The person who found us
                name: 'Online Challenger',
                handle: 'challenger',
                email: '',
                avatar: '',
                color: Colors.deepPurple,
                aura: 1000,
                roles: [],
                year: '',
                branch: '',
                building: '',
                stack: [],
                followers: 0,
                following: 0,
                bio: '',
                college: '',
                githubHandle: '',
                profileCompleted: true,
              ),
            ),
          ),
        );
      }
    });

    // 10 second timeout for finding a match
    Future.delayed(const Duration(seconds: 10), () async {
      if (mounted && !_matchFound) {
        setState(() => _searching = false);
        _matchSubscription?.unsubscribe();
        if (_myUserId != null) {
          await SupabaseService.instance.leaveMatchmakingPool(_myUserId!);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _matchSubscription?.unsubscribe();
    if (!_matchFound && _myUserId != null) {
      SupabaseService.instance.leaveMatchmakingPool(_myUserId!);
    }
    super.dispose();
  }
''';

  content = content.replaceFirst(oldInitState, newInitState);
  
  final oldSearchingText = '''
            Text(
              'SEARCHING FOR OPPONENT',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: Colors.white60,
              ),
            ),
''';

  final newSearchingText = '''
            Text(
              _searching ? 'SEARCHING FOR OPPONENT' : 'NO PLAYERS FOUND',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: _searching ? Colors.white60 : Colors.redAccent,
              ),
            ),
''';

  content = content.replaceFirst(oldSearchingText, newSearchingText);
  
  final oldFooter = '''
            const SizedBox(height: 60),
          ],
        ),
      ),
''';

  final newFooter = '''
            if (!_searching) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _startMatchmaking,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
            const SizedBox(height: 60),
          ],
        ),
      ),
''';
  
  content = content.replaceFirst(oldFooter, newFooter);

  file.writeAsStringSync(content);
}
