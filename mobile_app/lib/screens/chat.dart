import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class ChatScreen extends StatefulWidget {
  final int threadId;
  final int matchId;
  final String? otherName;
  final String? otherPhotoUrl;

  const ChatScreen({
    super.key,
    required this.threadId,
    required this.matchId,
    this.otherName,
    this.otherPhotoUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<dynamic> _messages = [];
  bool _loading = true;
  bool _sending = false;
  late int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = context.read<AuthProvider>().currentUserId;
    _loadMessages();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final msgs = await context.read<AuthService>().fetchMessages(widget.threadId);
    if (!mounted) return;
    setState(() {
      _messages = msgs ?? [];
      _loading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final msg = await context
        .read<AuthService>()
        .sendMessage(widget.threadId, text);
    if (!mounted) return;
    if (msg != null) {
      _messageCtrl.clear();
      setState(() => _messages.add(msg));
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send. Try again.')),
      );
    }
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.otherName ?? 'Match #${widget.matchId}';
    final photoUrl = widget.otherPhotoUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
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
                          errorWidget: (_, __, ___) =>
                              _InitialAvatar(name: name),
                        )
                      : _InitialAvatar(name: name),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(name,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.pink))
                : _messages.isEmpty
                    ? const Center(
                        child: Text('No messages yet. Say hello! 👋',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 15)))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = _messages[i];
                          final isMine =
                              (msg['sender_user_id'] as int?) ==
                                  _currentUserId;
                          return _MessageBubble(
                            content: msg['content'] as String,
                            timestamp: msg['created_at'] as String? ?? '',
                            isMine: isMine,
                            otherPhotoUrl: photoUrl,
                            otherName: name,
                          );
                        },
                      ),
          ),
          _InputBar(
            controller: _messageCtrl,
            sending: _sending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final String content;
  final String timestamp;
  final bool isMine;
  final String? otherPhotoUrl;
  final String otherName;

  const _MessageBubble({
    required this.content,
    required this.timestamp,
    required this.isMine,
    required this.otherPhotoUrl,
    required this.otherName,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr =
        timestamp.length >= 16 ? timestamp.substring(11, 16) : timestamp;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            _SmallAvatar(photoUrl: otherPhotoUrl, name: otherName),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.68,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient:
                        isMine ? AppColors.gradient : null,
                    color: isMine ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMine ? 18 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    content,
                    style: TextStyle(
                      color: isMine ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: const TextStyle(
                      fontSize: 10, color: Colors.black38),
                ),
              ],
            ),
          ),
          if (isMine) const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  const _SmallAvatar({required this.photoUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
          shape: BoxShape.circle, gradient: AppColors.gradient),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: ClipOval(
          child: photoUrl != null
              ? CachedNetworkImage(
                  imageUrl: photoUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _InitialAvatar(name: name, size: 10),
                )
              : _InitialAvatar(name: name, size: 10),
        ),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String name;
  final double size;
  const _InitialAvatar({required this.name, this.size = 15});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFE0EE),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.bold,
              color: AppColors.pink),
        ),
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          14, 8, 14, MediaQuery.of(context).padding.bottom + 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Type a message…',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF3F3F3),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: sending ? null : AppColors.gradient,
                color: sending ? Colors.grey.shade300 : null,
              ),
              child: sending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
