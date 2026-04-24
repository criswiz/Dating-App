import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/auth_widgets.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  List<dynamic> _profiles = [];
  bool _loading = true;
  String? _statusMessage;

  // Active filters
  final _searchCtrl = TextEditingController();
  int? _minAge;
  int? _maxAge;
  String? _filterIntent;
  String? _filterTribe;
  String? _filterReligion;
  String? _filterRelationshipStatus;
  String? _filterHasKids;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    setState(() => _loading = true);
    final profiles = await context.read<AuthService>().fetchProfiles(
          minAge: _minAge,
          maxAge: _maxAge,
          intent: _filterIntent,
          tribe: _filterTribe,
          religion: _filterReligion,
          relationshipStatus: _filterRelationshipStatus,
          hasKids: _filterHasKids,
          search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() {
      _profiles = profiles ?? [];
      _loading = false;
      _statusMessage = null;
    });
  }

  Future<void> _handleInteraction(int targetUserId, bool isLike) async {
    final auth = context.read<AuthService>();
    final response = isLike
        ? await auth.likeProfile(targetUserId)
        : await auth.passProfile(targetUserId);
    if (!mounted) return;

    setState(() => _profiles.removeAt(0));

    if (response == null) {
      setState(() => _statusMessage = 'Action failed. Please try again.');
      return;
    }
    if (response['matched'] == true) {
      _showMatchOverlay();
    } else {
      setState(() => _statusMessage = null);
    }

    if (_profiles.length <= 2) _loadProfiles();
  }

  void _showMatchOverlay() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: child,
      ),
      pageBuilder: (ctx, _, __) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (b) => AppColors.gradient.createShader(b),
                child: const Text(
                  "It's a Match!",
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You both liked each other.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 36),
              GradientButton(
                label: 'Go to Matches',
                onPressed: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Keep swiping',
                  style: TextStyle(color: Colors.white60, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
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

  void _openFilters() {
    // Temporary state inside sheet
    int? tmpMin = _minAge;
    int? tmpMax = _maxAge;
    String? tmpIntent = _filterIntent;
    String? tmpReligion = _filterReligion;
    String? tmpRelationshipStatus = _filterRelationshipStatus;
    String? tmpHasKids = _filterHasKids;
    final tribeCtrl = TextEditingController(text: _filterTribe ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filters',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setSheet(() {
                        tmpMin = null;
                        tmpMax = null;
                        tmpIntent = null;
                        tmpReligion = null;
                        tmpRelationshipStatus = null;
                        tmpHasKids = null;
                        tribeCtrl.clear();
                      });
                    },
                    child: const Text('Clear all',
                        style: TextStyle(color: AppColors.pink)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Age range
              const Text('Age range',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _FilterTextField(
                      label: 'Min age',
                      initialValue: tmpMin?.toString() ?? '',
                      keyboardType: TextInputType.number,
                      onChanged: (v) =>
                          setSheet(() => tmpMin = int.tryParse(v)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FilterTextField(
                      label: 'Max age',
                      initialValue: tmpMax?.toString() ?? '',
                      keyboardType: TextInputType.number,
                      onChanged: (v) =>
                          setSheet(() => tmpMax = int.tryParse(v)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Intent
              const Text('Looking for',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ['Serious', 'Casual', 'Friendship', 'Networking']
                    .map((opt) {
                  final selected = tmpIntent == opt;
                  return ChoiceChip(
                    label: Text(opt),
                    selected: selected,
                    onSelected: (v) =>
                        setSheet(() => tmpIntent = v ? opt : null),
                    selectedColor: AppColors.pink.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.pink,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.pink : Colors.black87,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                        color: selected ? AppColors.pink : Colors.grey.shade300),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Tribe
              const Text('Tribe',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              _FilterTextField(
                label: 'e.g. Yoruba, Zulu, Cherokee…',
                initialValue: tribeCtrl.text,
                controller: tribeCtrl,
                onChanged: (_) {},
              ),
              const SizedBox(height: 20),

              // Religion
              const Text('Religion',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  'Christianity', 'Islam', 'Hinduism', 'Buddhism', 'Judaism',
                  'Sikhism', 'Traditional / Spiritual', 'Atheism', 'Agnosticism', 'Other',
                ].map((opt) {
                  final selected = tmpReligion == opt;
                  return ChoiceChip(
                    label: Text(opt),
                    selected: selected,
                    onSelected: (v) =>
                        setSheet(() => tmpReligion = v ? opt : null),
                    selectedColor: AppColors.pink.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.pink,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.pink : Colors.black87,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                        color: selected ? AppColors.pink : Colors.grey.shade300),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Relationship status
              const Text('Relationship status',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  'Single', 'Divorced', 'Widowed', 'Separated',
                ].map((opt) {
                  final selected = tmpRelationshipStatus == opt;
                  return ChoiceChip(
                    label: Text(opt),
                    selected: selected,
                    onSelected: (v) =>
                        setSheet(() => tmpRelationshipStatus = v ? opt : null),
                    selectedColor: AppColors.pink.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.pink,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.pink : Colors.black87,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                        color: selected ? AppColors.pink : Colors.grey.shade300),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Has kids
              const Text('Has kids',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ['Yes', 'No'].map((opt) {
                  final selected = tmpHasKids == opt;
                  return ChoiceChip(
                    label: Text(opt),
                    selected: selected,
                    onSelected: (v) =>
                        setSheet(() => tmpHasKids = v ? opt : null),
                    selectedColor: AppColors.pink.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.pink,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.pink : Colors.black87,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                        color: selected ? AppColors.pink : Colors.grey.shade300),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              GradientButton(
                label: 'Apply filters',
                onPressed: () {
                  setState(() {
                    _minAge = tmpMin;
                    _maxAge = tmpMax;
                    _filterIntent = tmpIntent;
                    _filterTribe = tribeCtrl.text.trim().isEmpty
                        ? null
                        : tribeCtrl.text.trim();
                    _filterReligion = tmpReligion;
                    _filterRelationshipStatus = tmpRelationshipStatus;
                    _filterHasKids = tmpHasKids;
                  });
                  Navigator.pop(ctx);
                  _loadProfiles();
                },
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  bool get _hasActiveFilters =>
      _minAge != null ||
      _maxAge != null ||
      _filterIntent != null ||
      _filterTribe != null ||
      _filterReligion != null ||
      _filterRelationshipStatus != null ||
      _filterHasKids != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.tune_rounded),
                if (_hasActiveFilters)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.pink,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _openFilters,
            tooltip: 'Filters',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfiles,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name, city or bio…',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.pink, size: 22),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.grey, size: 20),
                        onPressed: () {
                          _searchCtrl.clear();
                          _loadProfiles();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.pink, width: 1.5),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _loadProfiles(),
              onChanged: (v) {
                setState(() {}); // update clear button visibility
                if (v.isEmpty) _loadProfiles();
              },
            ),
          ),

          // Active filter chips
          if (_hasActiveFilters)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  if (_minAge != null || _maxAge != null)
                    _FilterChip(
                      label: '${_minAge ?? '?'} – ${_maxAge ?? '?'} yrs',
                      onRemove: () {
                        setState(() {
                          _minAge = null;
                          _maxAge = null;
                        });
                        _loadProfiles();
                      },
                    ),
                  if (_filterIntent != null)
                    _FilterChip(
                      label: _filterIntent!,
                      onRemove: () {
                        setState(() => _filterIntent = null);
                        _loadProfiles();
                      },
                    ),
                  if (_filterTribe != null)
                    _FilterChip(
                      label: _filterTribe!,
                      onRemove: () {
                        setState(() => _filterTribe = null);
                        _loadProfiles();
                      },
                    ),
                  if (_filterReligion != null)
                    _FilterChip(
                      label: _filterReligion!,
                      onRemove: () {
                        setState(() => _filterReligion = null);
                        _loadProfiles();
                      },
                    ),
                  if (_filterRelationshipStatus != null)
                    _FilterChip(
                      label: _filterRelationshipStatus!,
                      onRemove: () {
                        setState(() => _filterRelationshipStatus = null);
                        _loadProfiles();
                      },
                    ),
                  if (_filterHasKids != null)
                    _FilterChip(
                      label: 'Kids: ${_filterHasKids!}',
                      onRemove: () {
                        setState(() => _filterHasKids = null);
                        _loadProfiles();
                      },
                    ),
                ],
              ),
            ),

          if (_statusMessage != null)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: AppColors.pink.withValues(alpha: 0.1),
              child: Text(
                _statusMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.pink, fontWeight: FontWeight.w500),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.pink))
                : _profiles.isEmpty
                    ? _EmptyState(onRefresh: _loadProfiles)
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

// ── Filter chip pill ──────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.pink.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pink.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.pink,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 14, color: AppColors.pink),
          ),
        ],
      ),
    );
  }
}

// ── Filter text field ─────────────────────────────────────────────────────────

class _FilterTextField extends StatelessWidget {
  final String label;
  final String initialValue;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const _FilterTextField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: controller == null ? initialValue : null,
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.pink, width: 1.5),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.explore_off_rounded, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No profiles match your filters.',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 20),
          GradientButton(label: 'Refresh', onPressed: onRefresh),
        ],
      ),
    );
  }
}

// ── Card deck ─────────────────────────────────────────────────────────────────

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

  void _onDragEnd(DragEndDetails _) {
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

    final size = MediaQuery.of(context).size;
    final cardW = size.width - 32;
    final cardH = size.height * 0.62;
    final angle = _dragging ? (_dragOffset.dx / size.width) * 0.4 : 0.0;
    final swipeRight = _dragging && _dragOffset.dx > 30;
    final swipeLeft = _dragging && _dragOffset.dx < -30;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Background card (explicitly centered)
        if (widget.profiles.length > 1)
          Align(
            alignment: const Alignment(0, -0.85),
            child: _ProfileCard(
              profile: widget.profiles[1],
              width: cardW,
              height: cardH,
              opacity: 0.55,
              scale: 0.93,
            ),
          ),
        // Top draggable card (explicitly centered)
        Center(
          child: GestureDetector(
            onPanUpdate: _onDragUpdate,
            onPanEnd: _onDragEnd,
            child: Transform.translate(
              offset: _dragOffset,
              child: Transform.rotate(
                angle: angle,
                child: Stack(
                  children: [
                    _ProfileCard(profile: _top, width: cardW, height: cardH),
                    if (swipeRight)
                      Positioned(
                        top: 28,
                        left: 20,
                        child: _SwipeLabel('LIKE', Colors.green),
                      ),
                    if (swipeLeft)
                      Positioned(
                        top: 28,
                        right: 20,
                        child: _SwipeLabel('NOPE', Colors.red),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Action buttons
        Positioned(
          bottom: 28,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                icon: Icons.close_rounded,
                color: Colors.red.shade400,
                size: 58,
                onTap: () => widget.onPass(_top['id'] as int),
              ),
              const SizedBox(width: 20),
              _ActionButton(
                icon: Icons.favorite_rounded,
                color: AppColors.pink,
                size: 68,
                gradient: true,
                onTap: () => widget.onLike(_top['id'] as int),
              ),
              const SizedBox(width: 20),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded,
                    color: Colors.grey.shade500, size: 26),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
}

// ── Profile card ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final dynamic profile;
  final double width;
  final double height;
  final double opacity;
  final double scale;

  const _ProfileCard({
    required this.profile,
    required this.width,
    required this.height,
    this.opacity = 1.0,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = profile['photo_url'] as String?;
    final name = profile['name'] as String? ?? 'Unknown';
    final age = profile['age'];
    final city = profile['city'] as String?;
    final tribe = profile['tribe'] as String?;
    final bio = profile['bio'] as String?;

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Photo
                photoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.pink)),
                        ),
                        errorWidget: (_, __, ___) => _AvatarFallback(),
                      )
                    : _AvatarFallback(),
                // Gradient overlay
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black87],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (age != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '$age',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 20),
                              ),
                            ],
                          ],
                        ),
                        if (city != null && city.isNotEmpty ||
                            tribe != null && tribe.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (city != null && city.isNotEmpty) ...[
                                const Icon(Icons.location_on_rounded,
                                    size: 13, color: Colors.white60),
                                const SizedBox(width: 3),
                                Text(city,
                                    style: const TextStyle(
                                        color: Colors.white60, fontSize: 13)),
                              ],
                              if (city != null &&
                                  city.isNotEmpty &&
                                  tribe != null &&
                                  tribe.isNotEmpty)
                                const Text('  ·  ',
                                    style: TextStyle(
                                        color: Colors.white38, fontSize: 13)),
                              if (tribe != null && tribe.isNotEmpty) ...[
                                const Icon(Icons.group_rounded,
                                    size: 13, color: Colors.white60),
                                const SizedBox(width: 3),
                                Text(tribe,
                                    style: const TextStyle(
                                        color: Colors.white60, fontSize: 13)),
                              ],
                            ],
                          ),
                        ],
                        if (bio != null && bio.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            bio,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE0EE), Color(0xFFE8D5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.person_rounded, size: 100, color: Colors.white),
    );
  }
}

// ── Swipe label ───────────────────────────────────────────────────────────────

class _SwipeLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SwipeLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: text == 'LIKE' ? -0.3 : 0.3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool gradient;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
    this.gradient = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient ? AppColors.gradient : null,
          color: gradient ? null : Colors.white,
          boxShadow: [
            BoxShadow(
              color: gradient
                  ? AppColors.pink.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon,
            color: gradient ? Colors.white : color, size: size * 0.46),
      ),
    );
  }
}
