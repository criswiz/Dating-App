import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'chat.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<dynamic> _matches = [];
  Map<int, int> _matchToThread = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final results = await Future.wait([
      auth.fetchMatches(),
      auth.fetchThreads(),
    ]);
    if (!mounted) return;
    final matches = results[0] ?? [];
    final threads = results[1] ?? [];
    final matchToThread = <int, int>{};
    for (final t in threads) {
      matchToThread[t['match_id'] as int] = t['id'] as int;
    }
    setState(() {
      _matches = matches;
      _matchToThread = matchToThread;
      _loading = false;
    });
  }

  void _openChat(dynamic match) {
    final matchId = match['id'] as int;
    final threadId = _matchToThread[matchId];
    if (threadId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          threadId: threadId,
          matchId: matchId,
          otherName: match['other_name'] as String?,
          otherPhotoUrl: match['other_photo_url'] as String?,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.pink))
          : _matches.isEmpty
              ? _EmptyMatches()
              : CustomScrollView(
                  slivers: [
                    // ── New Matches horizontal row ──────────────────────────
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
                            child: Text(
                              'New Matches',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 110,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: _matches.length,
                              itemBuilder: (ctx, i) {
                                final m = _matches[i];
                                final hasThread =
                                    _matchToThread.containsKey(m['id'] as int);
                                return _NewMatchAvatar(
                                  match: m,
                                  hasThread: hasThread,
                                  onTap: () => _openChat(m),
                                );
                              },
                            ),
                          ),
                          const Divider(height: 24),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: Text(
                              'Messages',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Conversation list ───────────────────────────────────
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final m = _matches[i];
                          final matchId = m['id'] as int;
                          final hasThread =
                              _matchToThread.containsKey(matchId);
                          return _ConversationTile(
                            match: m,
                            hasThread: hasThread,
                            onTap: () => _openChat(m),
                          );
                        },
                        childCount: _matches.length,
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ── New match avatar bubble ───────────────────────────────────────────────────

class _NewMatchAvatar extends StatelessWidget {
  final dynamic match;
  final bool hasThread;
  final VoidCallback onTap;

  const _NewMatchAvatar(
      {required this.match, required this.hasThread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = match['other_name'] as String? ?? 'Match';
    final photoUrl = match['other_photo_url'] as String?;

    return GestureDetector(
      onTap: hasThread ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.gradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.pink.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.5),
                    child: ClipOval(
                      child: photoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: photoUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  _AvatarPlaceholder(name: name),
                            )
                          : _AvatarPlaceholder(name: name),
                    ),
                  ),
                ),
                if (hasThread)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.pink,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 68,
              child: Text(
                name.split(' ').first,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Conversation tile ─────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final dynamic match;
  final bool hasThread;
  final VoidCallback onTap;

  const _ConversationTile(
      {required this.match, required this.hasThread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = match['other_name'] as String? ?? 'Match';
    final photoUrl = match['other_photo_url'] as String?;
    final age = match['other_age'];
    final matchedAt = match['created_at'] as String? ?? '';
    final dateStr =
        matchedAt.length >= 10 ? matchedAt.substring(0, 10) : matchedAt;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.gradient,
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: ClipOval(
            child: photoUrl != null
                ? CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _AvatarPlaceholder(name: name),
                  )
                : _AvatarPlaceholder(name: name),
          ),
        ),
      ),
      title: Text(
        age != null ? '$name, $age' : name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        hasThread ? 'Tap to say hello 👋' : 'Matched on $dateStr',
        style: TextStyle(
            color: hasThread ? AppColors.pink : Colors.grey,
            fontSize: 13),
      ),
      trailing: hasThread
          ? const Icon(Icons.chat_bubble_rounded,
              color: AppColors.pink, size: 22)
          : const Icon(Icons.lock_clock_outlined,
              color: Colors.grey, size: 20),
      onTap: hasThread ? onTap : null,
    );
  }
}

// ── Avatar placeholder ────────────────────────────────────────────────────────

class _AvatarPlaceholder extends StatelessWidget {
  final String name;
  const _AvatarPlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFE0EE),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.pink),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyMatches extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border_rounded,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No matches yet.',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Keep swiping!',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}
