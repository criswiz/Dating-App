import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;

  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();
  final _intentCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _interestsCtrl = TextEditingController();

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
    _genderCtrl.dispose();
    _intentCtrl.dispose();
    _cityCtrl.dispose();
    _interestsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final auth = context.read<AuthService>();
    final data = await auth.fetchMyProfile();
    if (!mounted) return;
    if (data != null) {
      _nameCtrl.text = data['name'] ?? '';
      _bioCtrl.text = data['bio'] ?? '';
      _ageCtrl.text = data['age']?.toString() ?? '';
      _genderCtrl.text = data['gender'] ?? '';
      _intentCtrl.text = data['intent'] ?? '';
      _cityCtrl.text = data['city'] ?? '';
      _interestsCtrl.text = data['interests'] ?? '';
    }
    setState(() {
      _profile = data;
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    final auth = context.read<AuthService>();
    final fields = <String, dynamic>{};
    if (_nameCtrl.text.trim().isNotEmpty) fields['name'] = _nameCtrl.text.trim();
    if (_bioCtrl.text.trim().isNotEmpty) fields['bio'] = _bioCtrl.text.trim();
    final age = int.tryParse(_ageCtrl.text.trim());
    if (age != null) fields['age'] = age;
    if (_genderCtrl.text.trim().isNotEmpty) fields['gender'] = _genderCtrl.text.trim();
    if (_intentCtrl.text.trim().isNotEmpty) fields['intent'] = _intentCtrl.text.trim();
    if (_cityCtrl.text.trim().isNotEmpty) fields['city'] = _cityCtrl.text.trim();
    if (_interestsCtrl.text.trim().isNotEmpty) fields['interests'] = _interestsCtrl.text.trim();

    final updated = await auth.updateProfile(fields);
    if (!mounted) return;
    if (updated != null) {
      setState(() => _profile = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save. Try again.')),
      );
    }
    setState(() => _saving = false);
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() => _uploadingPhoto = true);
    final auth = context.read<AuthService>();
    final updated = await auth.uploadPhoto(File(picked.path));
    if (!mounted) return;
    if (updated != null) {
      setState(() => _profile = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo updated')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo upload failed. Try again.')),
      );
    }
    setState(() => _uploadingPhoto = false);
  }

  void _logout() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveProfile,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Photo
                  GestureDetector(
                    onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: Colors.pink.shade100,
                          backgroundImage: _profile?['photo_url'] != null
                              ? NetworkImage(_profile!['photo_url'] as String)
                              : null,
                          child: _profile?['photo_url'] == null
                              ? const Icon(Icons.person, size: 52, color: Colors.pink)
                              : null,
                        ),
                        if (_uploadingPhoto)
                          const CircleAvatar(
                            radius: 52,
                            backgroundColor: Colors.black26,
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.pink,
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _profile?['email'] as String? ?? '',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  // Fields
                  _field('Name', _nameCtrl),
                  _field('Bio', _bioCtrl, maxLines: 3),
                  _field('Age', _ageCtrl, keyboardType: TextInputType.number),
                  _field('Gender', _genderCtrl),
                  _field('Looking for (intent)', _intentCtrl),
                  _field('City', _cityCtrl),
                  _field('Interests (comma-separated)', _interestsCtrl),

                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: _logout,
                    child: const Text('Log out', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
