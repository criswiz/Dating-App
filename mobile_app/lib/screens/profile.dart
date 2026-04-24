import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/auth_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;

  // About
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  // Details
  final _cityCtrl = TextEditingController();
  final _tribeCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _languagesCtrl = TextEditingController();

  // Dropdowns
  String? _gender;
  String? _intent;
  String? _education;
  String? _relationshipStatus;
  String? _hasKids;
  String? _wantKids;
  String? _religion;
  String? _drinking;
  String? _smoking;
  String? _exercise;

  // Interests
  final Set<String> _selectedInterests = {};

  static const _genders = ['Man', 'Woman', 'Non-binary', 'Other'];
  static const _intents = ['Serious', 'Casual', 'Friendship', 'Networking'];
  static const _educationOptions = [
    'High School', "Associate's", "Bachelor's", "Master's",
    'PhD', 'Trade / Vocational', 'Other',
  ];
  static const _relationshipStatuses = [
    'Single', 'Married', 'Divorced', 'Widowed', 'Separated',
    'Open relationship',
  ];
  static const _kidsOptions = ['Yes', 'No', 'Sometimes (shared custody)'];
  static const _wantKidsOptions = ['Yes', 'No', 'Maybe', 'Not sure'];
  static const _religions = [
    'Christianity', 'Islam', 'Hinduism', 'Buddhism', 'Judaism',
    'Sikhism', 'Traditional / Spiritual', 'Atheism', 'Agnosticism', 'Other',
  ];
  static const _drinkingOptions = ['Never', 'Rarely', 'Socially', 'Regularly'];
  static const _smokingOptions = ['Never', 'Rarely', 'Socially', 'Regularly'];
  static const _exerciseOptions = ['Never', 'Rarely', 'Sometimes', 'Often', 'Daily'];
  static const _allInterests = [
    'Music', 'Travel', 'Fitness', 'Food', 'Gaming',
    'Art', 'Reading', 'Film', 'Outdoors', 'Cooking', 'Pets', 'Tech',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _ageCtrl.dispose();
    _cityCtrl.dispose();
    _tribeCtrl.dispose();
    _occupationCtrl.dispose();
    _heightCtrl.dispose();
    _languagesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final data = await context.read<AuthService>().fetchMyProfile();
    if (!mounted) return;
    if (data != null) {
      _nameCtrl.text = data['name'] ?? '';
      _bioCtrl.text = data['bio'] ?? '';
      _ageCtrl.text = data['age']?.toString() ?? '';
      _cityCtrl.text = data['city'] ?? '';
      _tribeCtrl.text = data['tribe'] ?? '';
      _occupationCtrl.text = data['occupation'] ?? '';
      _heightCtrl.text = data['height']?.toString() ?? '';
      _languagesCtrl.text = data['languages'] ?? '';
      _gender = _pick(_genders, data['gender']);
      _intent = _pick(_intents, data['intent']);
      _education = _pick(_educationOptions, data['education']);
      _relationshipStatus = _pick(_relationshipStatuses, data['relationship_status']);
      _hasKids = _pick(_kidsOptions, data['has_kids']);
      _wantKids = _pick(_wantKidsOptions, data['want_kids']);
      _religion = _pick(_religions, data['religion']);
      _drinking = _pick(_drinkingOptions, data['drinking']);
      _smoking = _pick(_smokingOptions, data['smoking']);
      _exercise = _pick(_exerciseOptions, data['exercise']);
      final interests = (data['interests'] as String?) ?? '';
      _selectedInterests
        ..clear()
        ..addAll(
          interests.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
        );
    }
    setState(() {
      _profile = data;
      _loading = false;
    });
  }

  String? _pick(List<String> options, dynamic value) =>
      options.contains(value) ? value as String : null;

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    final fields = <String, dynamic>{};

    void addStr(String key, TextEditingController ctrl) {
      if (ctrl.text.trim().isNotEmpty) fields[key] = ctrl.text.trim();
    }
    void addDropdown(String key, String? value) {
      if (value != null) fields[key] = value;
    }

    addStr('name', _nameCtrl);
    addStr('bio', _bioCtrl);
    final age = int.tryParse(_ageCtrl.text.trim());
    if (age != null) fields['age'] = age;
    addStr('city', _cityCtrl);
    addStr('tribe', _tribeCtrl);
    addStr('occupation', _occupationCtrl);
    addStr('languages', _languagesCtrl);
    final height = int.tryParse(_heightCtrl.text.trim());
    if (height != null) fields['height'] = height;
    addDropdown('gender', _gender);
    addDropdown('intent', _intent);
    addDropdown('education', _education);
    addDropdown('relationship_status', _relationshipStatus);
    addDropdown('has_kids', _hasKids);
    addDropdown('want_kids', _wantKids);
    addDropdown('religion', _religion);
    addDropdown('drinking', _drinking);
    addDropdown('smoking', _smoking);
    addDropdown('exercise', _exercise);
    fields['interests'] = _selectedInterests.join(', ');

    final updated = await context.read<AuthService>().updateProfile(fields);
    if (!mounted) return;
    setState(() {
      if (updated != null) _profile = updated;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(updated != null ? 'Profile saved!' : 'Save failed. Try again.'),
        backgroundColor: updated != null ? AppColors.pink : Colors.red,
      ),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    if (!mounted) return;
    final auth = context.read<AuthService>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _uploadingPhoto = true);
    final updated = await auth.uploadPhoto(File(picked.path));
    if (!mounted) return;
    if (updated != null) setState(() => _profile = updated);
    setState(() => _uploadingPhoto = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(updated != null ? 'Photo updated!' : 'Upload failed.'),
        backgroundColor: updated != null ? AppColors.pink : Colors.red,
      ),
    );
  }

  void _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.pink))
          : CustomScrollView(
              slivers: [
                // ── Gradient header ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _ProfileHeader(
                    profile: _profile,
                    uploadingPhoto: _uploadingPhoto,
                    onTapPhoto: _uploadingPhoto ? null : _pickAndUploadPhoto,
                  ),
                ),

                // ── About ───────────────────────────────────────────────────
                _section('About', [
                  AuthField(
                    controller: _nameCtrl,
                    label: 'Full name',
                    icon: Icons.person_outline,
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _bioCtrl,
                    maxLines: 3,
                    decoration: _multilineDecoration('Bio', Icons.edit_note_outlined),
                  ),
                  const SizedBox(height: 14),
                  AuthField(
                    controller: _ageCtrl,
                    label: 'Age',
                    icon: Icons.cake_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ]),

                // ── Details ─────────────────────────────────────────────────
                _section('Details', [
                  _dropdown('Gender', Icons.wc_outlined, _gender, _genders,
                      (v) => setState(() => _gender = v)),
                  const SizedBox(height: 14),
                  _dropdown('Looking for', Icons.favorite_outline, _intent, _intents,
                      (v) => setState(() => _intent = v)),
                  const SizedBox(height: 14),
                  AuthField(
                    controller: _cityCtrl,
                    label: 'City',
                    icon: Icons.location_city_outlined,
                  ),
                  const SizedBox(height: 14),
                  AuthField(
                    controller: _tribeCtrl,
                    label: 'Tribe (e.g. Yoruba, Zulu…)',
                    icon: Icons.group_outlined,
                  ),
                  const SizedBox(height: 14),
                  AuthField(
                    controller: _occupationCtrl,
                    label: 'Occupation',
                    icon: Icons.work_outline,
                  ),
                  const SizedBox(height: 14),
                  AuthField(
                    controller: _heightCtrl,
                    label: 'Height (cm)',
                    icon: Icons.height,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  _dropdown('Education', Icons.school_outlined, _education,
                      _educationOptions, (v) => setState(() => _education = v)),
                  const SizedBox(height: 14),
                  AuthField(
                    controller: _languagesCtrl,
                    label: 'Languages spoken (e.g. English, French…)',
                    icon: Icons.translate_outlined,
                  ),
                ]),

                // ── Relationship ─────────────────────────────────────────────
                _section('Relationship', [
                  _dropdown('Relationship status', Icons.favorite_border,
                      _relationshipStatus, _relationshipStatuses,
                      (v) => setState(() => _relationshipStatus = v)),
                  const SizedBox(height: 14),
                  _dropdown('Have kids?', Icons.child_care_outlined, _hasKids,
                      _kidsOptions, (v) => setState(() => _hasKids = v)),
                  const SizedBox(height: 14),
                  _dropdown('Want kids?', Icons.child_friendly_outlined,
                      _wantKids, _wantKidsOptions,
                      (v) => setState(() => _wantKids = v)),
                  const SizedBox(height: 14),
                  _dropdown('Religion', Icons.auto_awesome_outlined, _religion,
                      _religions, (v) => setState(() => _religion = v)),
                ]),

                // ── Lifestyle ─────────────────────────────────────────────────
                _section('Lifestyle', [
                  _dropdown('Drinking', Icons.local_bar_outlined, _drinking,
                      _drinkingOptions, (v) => setState(() => _drinking = v)),
                  const SizedBox(height: 14),
                  _dropdown('Smoking', Icons.smoke_free_outlined, _smoking,
                      _smokingOptions, (v) => setState(() => _smoking = v)),
                  const SizedBox(height: 14),
                  _dropdown('Exercise', Icons.fitness_center_outlined, _exercise,
                      _exerciseOptions, (v) => setState(() => _exercise = v)),
                ]),

                // ── Interests ─────────────────────────────────────────────────
                _section('Interests', [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allInterests.map((interest) {
                      final selected = _selectedInterests.contains(interest);
                      return FilterChip(
                        label: Text(interest),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _selectedInterests.add(interest);
                          } else {
                            _selectedInterests.remove(interest);
                          }
                        }),
                        selectedColor: AppColors.pink.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.pink,
                        labelStyle: TextStyle(
                          color: selected ? AppColors.pink : Colors.black87,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: selected
                              ? AppColors.pink
                              : Colors.grey.shade300,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      );
                    }).toList(),
                  ),
                ]),

                // ── Save ─────────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: GradientButton(
                      label: 'Save profile',
                      loading: _saving,
                      onPressed: _saveProfile,
                    ),
                  ),
                ),

                // ── Log out ───────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Center(
                    child: TextButton(
                      onPressed: _logout,
                      child: const Text('Log out',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  SliverToBoxAdapter _section(String title, List<Widget> children) =>
      SliverToBoxAdapter(
        child: _SectionCard(title: title, children: children),
      );

  Widget _dropdown(
    String label,
    IconData icon,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) =>
      _DropdownField(
          label: label, icon: icon, value: value, items: items, onChanged: onChanged);

  InputDecoration _multilineDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(bottom: 42),
          child: Icon(icon, color: AppColors.pink, size: 20),
        ),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.pink, width: 1.5),
        ),
      );
}

// ── Profile header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final bool uploadingPhoto;
  final VoidCallback? onTapPhoto;

  const _ProfileHeader({
    required this.profile,
    required this.uploadingPhoto,
    required this.onTapPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = profile?['photo_url'] as String?;
    final name = profile?['name'] as String? ?? '';
    final email = profile?['email'] as String? ?? '';

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 28,
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTapPhoto,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: photoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                _PhotoFallback(name: name),
                          )
                        : _PhotoFallback(name: name),
                  ),
                ),
                if (uploadingPhoto)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 16, color: AppColors.pink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (name.isNotEmpty)
            Text(name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(email,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  final String name;
  const _PhotoFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white24,
      child: Center(
        child: name.isNotEmpty
            ? Text(name[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold))
            : const Icon(Icons.person_rounded, size: 52, color: Colors.white),
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

// ── Dropdown field ────────────────────────────────────────────────────────────

class _DropdownField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.pink, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                hint: Text(label,
                    style: const TextStyle(color: Colors.grey, fontSize: 15)),
                isExpanded: true,
                items: items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
