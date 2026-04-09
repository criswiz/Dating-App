import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({Key? key}) : super(key: key);

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  List<dynamic> _profiles = [];
  bool _loading = true;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _loading = true);
    final profiles = await context.read<AuthService>().fetchProfiles();
    if (!mounted) return;
    setState(() {
      _profiles = profiles ?? [];
      _loading = false;
    });
  }

  Future<void> _handleInteraction(int targetUserId, bool isLike) async {
    final auth = context.read<AuthService>();
    final response = isLike
        ? await auth.likeProfile(targetUserId)
        : await auth.passProfile(targetUserId);
    if (!mounted) return;

    // Remove top card
    setState(() => _profiles.removeAt(0));

    if (response == null) {
      setState(() => _statusMessage = 'Action failed. Please try again.');
      return;
    }
    final matched = response['matched'] == true;
    if (matched) {
      _showMatchDialog();
    } else {
      setState(() => _statusMessage = isLike ? 'Liked!' : null);
    }

    // Reload when deck runs low
    if (_profiles.length <= 2) _loadProfiles();
  }

  void _showMatchDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('It\'s a Match! 🎉'),
        content: const Text('You both liked each other. Open Matches to start chatting.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep swiping'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSafetyAction(int targetUserId, bool isBlock) async {
    final auth = context.read<AuthService>();
    final ok = isBlock
        ? await auth.blockUser(targetUserId, reason: 'User action from discover')
        : await auth.reportUser(targetUserId, 'User flagged from discover');
    if (!mounted) return;
    setState(() {
      _profiles.removeWhere((p) => p['id'] == targetUserId);
      _statusMessage = ok
          ? (isBlock ? 'User blocked.' : 'User reported.')
          : 'Action failed. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfiles,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Text(
                _statusMessage!,
                style: TextStyle(color: Colors.pink.shade700, fontWeight: FontWeight.w500),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _profiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('No more profiles right now.'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadProfiles,
                              child: const Text('Refresh'),
                            ),
                          ],
                        ),
                      )
                    : _CardDeck(
                        profiles: _profiles,
                        onLike: (id) => _handleInteraction(id, true),
                        onPass: (id) => _handleInteraction(id, false),
                        onBlock: (id) => _handleSafetyAction(id, true),
                        onReport: (id) => _handleSafetyAction(id, false),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Card deck with drag-to-swipe ────────────────────────────────────────────

class _CardDeck extends StatefulWidget {
  final List<dynamic> profiles;
  final void Function(int id) onLike;
  final void Function(int id) onPass;
  final void Function(int id) onBlock;
  final void Function(int id) onReport;

  const _CardDeck({
    required this.profiles,
    required this.onLike,
    required this.onPass,
    required this.onBlock,
    required this.onReport,
  });

  @override
  State<_CardDeck> createState() => _CardDeckState();
}

class _CardDeckState extends State<_CardDeck> {
  Offset _dragOffset = Offset.zero;
  bool _dragging = false;

  dynamic get _top => widget.profiles.isNotEmpty ? widget.profiles[0] : null;

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() {
      _dragOffset += d.delta;
      _dragging = true;
    });
  }

  void _onDragEnd(DragEndDetails d) {
    final dx = _dragOffset.dx;
    if (dx > 80) {
      widget.onLike(_top['id'] as int);
    } else if (dx < -80) {
      widget.onPass(_top['id'] as int);
    }
    setState(() {
      _dragOffset = Offset.zero;
      _dragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_top == null) return const SizedBox.shrink();

    final screenW = MediaQuery.of(context).size.width;
    final angle = _dragging ? (_dragOffset.dx / screenW) * 0.4 : 0.0;

    // Swipe feedback overlays
    final swipeRight = _dragging && _dragOffset.dx > 30;
    final swipeLeft = _dragging && _dragOffset.dx < -30;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Background card (next profile)
        if (widget.profiles.length > 1)
          Positioned(
            top: 24,
            child: _buildCard(widget.profiles[1], opacity: 0.6, scale: 0.94),
          ),
        // Top (draggable) card
        GestureDetector(
          onPanUpdate: _onDragUpdate,
          onPanEnd: _onDragEnd,
          child: Transform.translate(
            offset: _dragOffset,
            child: Transform.rotate(
              angle: angle,
              child: Stack(
                children: [
                  _buildCard(_top),
                  if (swipeRight)
                    Positioned(
                      top: 24, left: 16,
                      child: _swipeLabel('LIKE', Colors.green),
                    ),
                  if (swipeLeft)
                    Positioned(
                      top: 24, right: 16,
                      child: _swipeLabel('PASS', Colors.red),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Action buttons below the card
        Positioned(
          bottom: 24,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _actionButton(Icons.close, Colors.red, () => widget.onPass(_top['id'] as int)),
              const SizedBox(width: 24),
              _actionButton(Icons.favorite, Colors.green, () => widget.onLike(_top['id'] as int)),
              const SizedBox(width: 24),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: Colors.grey),
                onSelected: (v) {
                  if (v == 'block') widget.onBlock(_top['id'] as int);
                  if (v == 'report') widget.onReport(_top['id'] as int);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'report', child: Text('Report')),
                  PopupMenuItem(value: 'block', child: Text('Block')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(dynamic p, {double opacity = 1.0, double scale = 1.0}) {
    final photoUrl = p['photo_url'] as String?;
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 320,
          height: 460,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
            color: Colors.white,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: photoUrl != null
                      ? Image.network(photoUrl, fit: BoxFit.cover)
                      : Container(
                          color: Colors.pink.shade50,
                          child: const Icon(Icons.person, size: 120, color: Colors.pink),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            p['name'] ?? 'Unknown',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          if (p['age'] != null) ...[
                            const SizedBox(width: 6),
                            Text('${p['age']}', style: const TextStyle(fontSize: 18, color: Colors.black54)),
                          ],
                        ],
                      ),
                      if ((p['city'] as String?)?.isNotEmpty == true)
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                            Text(p['city'] as String, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      if ((p['bio'] as String?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(p['bio'] as String, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _swipeLabel(String text, Color color) {
    return Transform.rotate(
      angle: text == 'LIKE' ? -0.3 : 0.3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}
