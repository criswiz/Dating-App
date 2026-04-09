import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'chat.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({Key? key}) : super(key: key);

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  Future<List<dynamic>?>? _matchesFuture;
  Future<List<dynamic>?>? _threadsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final auth = context.read<AuthService>();
    _matchesFuture = auth.fetchMatches();
    _threadsFuture = auth.fetchThreads();
  }

  void _refresh() {
    setState(() => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<List<dynamic>?>(
        future: _matchesFuture,
        builder: (ctx, matchSnap) {
          if (matchSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final matches = matchSnap.data ?? [];
          if (matches.isEmpty) {
            return const Center(
              child: Text('No matches yet.\nKeep swiping!', textAlign: TextAlign.center),
            );
          }
          return FutureBuilder<List<dynamic>?>(
            future: _threadsFuture,
            builder: (ctx, threadSnap) {
              final threads = threadSnap.data ?? [];
              // Build a quick match_id → thread_id map
              final matchToThread = <int, int>{};
              for (final t in threads) {
                matchToThread[t['match_id'] as int] = t['id'] as int;
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: matches.length,
                itemBuilder: (ctx, i) {
                  final m = matches[i];
                  final matchId = m['id'] as int;
                  final threadId = matchToThread[matchId];
                  final matchedAt = m['created_at'] as String? ?? '';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.pink.shade100,
                      child: const Icon(Icons.person, color: Colors.pink),
                    ),
                    title: Text('Match #$matchId'),
                    subtitle: Text(
                      matchedAt.isNotEmpty ? 'Matched ${matchedAt.substring(0, 10)}' : '',
                    ),
                    trailing: threadId != null
                        ? const Icon(Icons.chat_bubble_outline, color: Colors.pink)
                        : const Icon(Icons.lock_clock, color: Colors.grey),
                    onTap: threadId != null
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  threadId: threadId,
                                  matchId: matchId,
                                ),
                              ),
                            )
                        : null,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
