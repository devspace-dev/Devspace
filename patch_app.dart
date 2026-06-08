import 'dart:io';

void main() {
  final file = File('lib/app.dart');
  var content = file.readAsStringSync();
  
  final injection = '''
  void _setupDuelRequestsListener(String userId) {
    _duelRequestsSubscription?.unsubscribe();
    _duelRequestsSubscription = SupabaseService.instance.listenToIncomingDuelRequests(userId, (request) {
      if (!mounted) return;
      _showIncomingDuelDialog(request);
    });
  }

  void _showIncomingDuelDialog(Map<String, dynamic> request) async {
    final senderId = request['sender_id'].toString();
    final sender = await context.read<UsersProvider>().getUserById(senderId);

    if (!mounted || sender == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.flash_on_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Incoming Challenge!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          '\${sender.name} has challenged you to a \${request['mode']} in \${request['category']}!',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
           TextButton(
             onPressed: () {
                SupabaseService.instance.updateDuelRequestStatus(request['id'].toString(), 'declined');
                Navigator.pop(ctx);
             },
             child: const Text('Decline', style: TextStyle(color: Colors.white54)),
           ),
           ElevatedButton(
             onPressed: () async {
                await SupabaseService.instance.updateDuelRequestStatus(request['id'].toString(), 'accepted');
                final me = context.read<AuthProvider>().currentUserOrNull;
                if (me != null) {
                  await SupabaseService.instance.createLiveDuel(
                    requestId: request['id'].toString(),
                    category: request['category'].toString(),
                    player1Id: request['sender_id'].toString(),
                    player2Id: me.id,
                  );
                }
                if (!mounted) return;
                Navigator.pop(ctx);
             },
             style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
             child: const Text('Accept', style: TextStyle(color: Colors.white)),
           ),
        ],
      )
    );
  }
''';

  content = content.replaceFirst('void _tierUpListener() {', injection + '\n  void _tierUpListener() {');
  file.writeAsStringSync(content);
}
