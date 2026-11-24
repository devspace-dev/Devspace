import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/colors.dart';
import '../core/theme/text.dart';
import '../core/widgets/ds_button.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import '../screens/duel_screen.dart';
import '../services/supabase_service.dart';

final Set<String> _openDuelInviteDialogIds = <String>{};

/// Resolves the sender, prevents duplicate popups for [request], and lets
/// the receiver accept (claiming the request, updating arena_matches, and
/// entering DuelScreen as Player 2) or decline.
Future<void> showIncomingDuelInviteDialog(
  BuildContext context,
  Map<String, dynamic> request,
) async {
  final requestId = request['id']?.toString() ?? '';
  if (requestId.isEmpty || _openDuelInviteDialogIds.contains(requestId)) {
    return;
  }

  final senderId = request['sender_id']?.toString() ?? '';
  final mode = request['mode']?.toString() ?? 'REFLEX MODE';
  final category = request['category']?.toString() ?? 'Combat';
  if (senderId.isEmpty) return;

  final usersProvider = context.read<UsersProvider>();
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.maybeOf(context);

  UserModel? sender = usersProvider.getUserById(senderId);
  if (sender == null) {
    try {
      sender = await usersProvider.getUser(senderId);
    } catch (e) {
      debugPrint('Failed loading duel challenger profile: $e');
    }
  }

  if (!context.mounted) return;

  final opponent = sender ??
      UserModel(
        id: senderId,
        name: 'Challenger',
        handle: 'peer',
        email: '',
        avatar: '',
        color: Ds.aura,
        aura: 0,
        roles: const ['Student'],
        year: '',
        branch: '',
        building: '',
        stack: const [],
        followers: 0,
        following: 0,
        bio: '',
        college: '',
        githubHandle: '',
        profileCompleted: true,
      );

  _openDuelInviteDialogIds.add(requestId);
  try {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        var submitting = false;
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              backgroundColor: Ds.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Ds.border, width: 2),
              ),
              title: Row(
                children: [
                  const Icon(Icons.flash_on_rounded, color: Ds.aura),
                  const SizedBox(width: 8),
                  Text('CHALLENGE!', style: DsText.h3),
                ],
              ),
              content: Text(
                '${opponent.name} challenged you to $mode in $category!',
                style: DsText.body.copyWith(color: Ds.muted),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          setDialogState(() => submitting = true);
                          try {
                            await SupabaseService.instance
                                .updateDuelRequestStatus(requestId, 'declined');
                          } catch (e) {
                            debugPrint('Failed declining duel invite: $e');
                          }
                          if (dialogCtx.mounted) {
                            Navigator.of(dialogCtx).pop();
                          }
                        },
                  child: Text(
                    'DECLINE',
                    style: DsText.label.copyWith(color: Ds.hot),
                  ),
                ),
                SizedBox(
                  width: 132,
                  child: DsButton(
                    label: 'ACCEPT',
                    height: 44,
                    loading: submitting,
                    onPressed: submitting
                        ? null
                        : () async {
                            final me = dialogCtx
                                .read<AuthProvider>()
                                .currentUserOrNull;
                            if (me == null) {
                              Navigator.of(dialogCtx).pop();
                              return;
                            }
                            setDialogState(() => submitting = true);
                            try {
                              final claimed = await SupabaseService.instance
                                  .acceptDuelRequestIfPending(requestId);
                              if (!claimed) {
                                if (dialogCtx.mounted) {
                                  Navigator.of(dialogCtx).pop();
                                }
                                messenger?.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'This challenge was cancelled or already handled.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              await SupabaseService.instance
                                  .acceptDuelRequestMatch(
                                matchId: requestId,
                                mode: mode,
                                player1Id: senderId,
                                player2Id: me.id,
                              );

                              if (dialogCtx.mounted) {
                                Navigator.of(dialogCtx).pop();
                              }
                              rootNavigator.push(
                                MaterialPageRoute(
                                  builder: (_) => DuelScreen(
                                    category: category,
                                    mode: mode,
                                    matchId: requestId,
                                    isPlayer1: false,
                                    opponent: opponent,
                                  ),
                                ),
                              );
                            } catch (e) {
                              debugPrint('Failed accepting duel invite: $e');
                              if (dialogCtx.mounted) {
                                setDialogState(() => submitting = false);
                              }
                              messenger?.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not join duel: ${SupabaseService.instance.cleanErrorText(e)}',
                                  ),
                                ),
                              );
                            }
                          },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    _openDuelInviteDialogIds.remove(requestId);
  }
}
