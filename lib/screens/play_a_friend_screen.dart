import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/colors.dart';
import '../core/theme/text.dart';
import '../core/widgets/ds_button.dart';
import '../core/widgets/ds_tag.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import '../services/supabase_service.dart';
import '../widgets/profile_card.dart';
import 'waiting_for_opponent_screen.dart';

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
  String _query = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<UserModel> _results = [];
  bool _isLoading = true;
  String? _error;
  String? _sendingToUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDirectory(query: '');
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDirectory({required String query}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final me = context.read<AuthProvider>().currentUserOrNull;
    final usersP = context.read<UsersProvider>();

    try {
      if (!SupabaseService.instance.isSupabaseReady) {
        final local = _sortAndFilterUsers(
          usersP.users,
          meId: me?.id,
          query: query,
        );
        if (!mounted) return;
        setState(() {
          _results = local;
          _isLoading = false;
        });
        return;
      }

      // Ensure followed friends are always hydrated even when not in the first directory page.
      if (me != null && query.isEmpty) {
        try {
          final followingIds =
              await SupabaseService.instance.getFollowingIds(me.id);
          if (followingIds.isNotEmpty) {
            await usersP.fetchAndCacheUsers(followingIds.toList());
          }
        } catch (_) {}
      }

      final searched = await usersP.searchDevelopers(
        query: query.isEmpty ? null : query,
        limit: 50,
      );

      final byId = <String, UserModel>{
        for (final u in searched) u.id: u,
      };
      if (query.isEmpty) {
        for (final cached in usersP.users) {
          byId.putIfAbsent(cached.id, () => cached);
        }
      }

      final merged = _sortAndFilterUsers(
        byId.values.toList(),
        meId: me?.id,
        query: query,
      );

      if (!mounted) return;
      setState(() {
        _results = merged;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('Failed loading duel builders: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not load builders. Tap retry.';
      });
    }
  }

  List<UserModel> _sortAndFilterUsers(
    List<UserModel> source, {
    required String? meId,
    required String query,
  }) {
    final trimmed = query.trim().toLowerCase();
    final filtered = source.where((u) {
      if (meId != null && u.id == meId) return false;
      if (trimmed.isEmpty) return true;
      final normalizedHandle = u.handle.toLowerCase();
      final queryNoAt = trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
      return u.name.toLowerCase().contains(trimmed) ||
          normalizedHandle.contains(queryNoAt) ||
          u.college.toLowerCase().contains(trimmed);
    }).toList();

    // Followed friends at top, then higher Aura, then alphabetical by name.
    filtered.sort((a, b) {
      if (a.isFollowing != b.isFollowing) {
        return a.isFollowing ? -1 : 1;
      }
      final auraCmp = b.aura.compareTo(a.aura);
      if (auraCmp != 0) return auraCmp;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return filtered;
  }

  void _onSearch(String value) {
    final nextQuery = value.trim();
    setState(() => _query = nextQuery);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _loadDirectory(query: nextQuery);
    });
  }

  Future<void> _challengeUser(UserModel opponent) async {
    if (_sendingToUserId != null) return;
    final me = context.read<AuthProvider>().currentUserOrNull;
    if (me == null) return;

    setState(() => _sendingToUserId = opponent.id);
    try {
      final requestId = await SupabaseService.instance.sendDuelRequest(
        senderId: me.id,
        receiverId: opponent.id,
        category: widget.category,
        mode: widget.mode,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WaitingForOpponentScreen(
            requestId: requestId,
            category: widget.category,
            mode: widget.mode,
            opponent: opponent,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _sendingToUserId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to start challenge: ${SupabaseService.instance.cleanErrorText(e)}',
            ),
            backgroundColor: Ds.hot,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final followedCount = _results.where((u) => u.isFollowing).length;

    return Scaffold(
      backgroundColor: Ds.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Back',
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Ds.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Ds.border),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Ds.bone,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Play a Friend', style: DsText.h3),
                        Text(widget.mode, style: DsText.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _searchController,
                onChanged: _onSearch,
                style: DsText.body,
                decoration: InputDecoration(
                  hintText: 'Search by name, @handle or college',
                  hintStyle: DsText.bodySm.copyWith(color: Ds.muted),
                  prefixIcon: const Icon(Icons.search_rounded, color: Ds.muted, size: 20),
                  filled: true,
                  fillColor: Ds.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Ds.border, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.color, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                _query.isEmpty
                    ? (followedCount > 0
                        ? 'FRIENDS FIRST · ALL BUILDERS'
                        : 'ALL BUILDERS')
                    : 'SEARCH RESULTS',
                style: DsText.caption.copyWith(letterSpacing: 1),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _results.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Ds.aura),
      );
    }

    if (_error != null && _results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Ds.muted),
            const SizedBox(height: 12),
            Text(_error!, style: DsText.bodySm.copyWith(color: Ds.muted)),
            const SizedBox(height: 16),
            SizedBox(
              width: 140,
              child: DsButton(
                label: 'Retry',
                height: 44,
                onPressed: () => _loadDirectory(query: _query),
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search_rounded,
              size: 56,
              color: widget.color.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              _query.isEmpty
                  ? 'No builders available yet'
                  : 'No builders match "$_query"',
              style: DsText.bodySm.copyWith(color: Ds.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final user = _results[i];
        final isSendingThis = _sendingToUserId == user.id;
        return ProfileCard(
          user: user,
          onTap: () => _challengeUser(user),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user.isFollowing) ...[
                const DsTag('FRIEND', bg: Ds.mintPanel, fg: Ds.mint),
                const SizedBox(width: 6),
              ],
              SizedBox(
                width: 84,
                child: DsButton(
                  label: 'Invite',
                  height: 38,
                  loading: isSendingThis,
                  onPressed:
                      _sendingToUserId != null ? null : () => _challengeUser(user),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
