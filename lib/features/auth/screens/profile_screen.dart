import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../trips/models/trip.dart';
import '../../trips/providers/trip_repository.dart';
import '../../trips/providers/trip_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _avatarUrlController;
  late TextEditingController _paymentInfoController;
  late TextEditingController _ibanController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    // Note: To get the full profile data (including payment info),
    // we should ideally be watching a stream of the profile table.
    // However, for now, we rely on what's available or fetch it.
    // Since currentUserProvider mainly comes from Auth Use and metadata
    // might not have the latest custom columns unless synced.
    // Better approach: Watch the profile document.

    _nameController = TextEditingController(
      text: user?.userMetadata?['full_name'] ?? '',
    );
    _avatarUrlController = TextEditingController(
      text: user?.userMetadata?['avatar_url'] ?? '',
    );
    _paymentInfoController = TextEditingController(text: '');
    _ibanController = TextEditingController(text: '');

    // Fetch latest profile data to populate fields
    if (user != null) {
      _loadProfile(user.id);
    }
  }

  Future<void> _loadProfile(String userId) async {
    try {
      final data = await ref.read(authRepositoryProvider).getProfile(userId);
      if (mounted && data != null) {
        setState(() {
          _nameController.text = data['full_name'] ?? '';
          _avatarUrlController.text = data['avatar_url'] ?? '';
          _paymentInfoController.text = data['payment_info'] ?? '';
          _ibanController.text = data['iban'] ?? '';
        });
      }
    } catch (e) {
      // Handle error or just rely on initial
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile == null) return;

      // Crop the image
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 70,
        maxWidth: 512,
        maxHeight: 512,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Avatar',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Avatar',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
          WebUiSettings(context: context),
        ],
      );

      if (croppedFile == null) return;

      setState(() => _isLoading = true);

      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final bytes = await croppedFile.readAsBytes();

      final newUrl = await ref
          .read(authRepositoryProvider)
          .uploadProfileImage(bytes, user.id);

      if (mounted) {
        setState(() {
          _avatarUrlController.text = newUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarUrlController.dispose();
    _paymentInfoController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      await ref
          .read(authRepositoryProvider)
          .updateUserProfile(
            user.id,
            name: _nameController.text.trim(),
            avatarUrl: _avatarUrlController.text.trim(),
            paymentInfo: _paymentInfoController.text.trim(),
            iban: _ibanController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Step 1: Check for sole leader trips
      final atRiskTrips = await ref
          .read(tripRepositoryProvider)
          .getSoleLeaderTrips(user.id);

      if (!mounted) return;

      if (atRiskTrips.isNotEmpty) {
        // Step 2: Show Warning
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Warning: You are a Sole Leader'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You are the ONLY leader for the following trips:',
                  ),
                  const SizedBox(height: 8),
                  ...atRiskTrips.map(
                    (t) => Text(
                      '• ${t.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'If you delete your account now, these trips and all their expenses will be permanently destroyed. We advise you to assign another leader first.',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Proceed Anyway',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );

        if (proceed != true) {
          setState(() => _isLoading = false);
          return;
        }
      }

      if (!mounted) return;

      // Step 3: Final Confirmation
      final confirmController = TextEditingController();
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Account Permanently?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This action cannot be undone. All your expenses, profile data, '
                'and trip memberships will be completely erased as if you never existed.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(
                  labelText: 'Type DELETE to confirm',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: confirmController,
              builder: (context, val, _) {
                return TextButton(
                  onPressed: val.text == 'DELETE'
                      ? () => Navigator.pop(context, true)
                      : null,
                  child: const Text(
                    'Confirm Deletion',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );

      if (confirm == true) {
        if (!mounted) return;
        // Proceed with deletion
        await ref.read(authRepositoryProvider).deleteAccount(user.id);
        // Auth state change will likely trigger redirection, but let's be safe
        // if user is already signed out by repo
        // Navigator pop happens automatically by auth state listener usually
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar Preview with Upload
              GestureDetector(
                onTap: _showImageSourceActionSheet,
                child: Stack(
                  children: [
                    ValueListenableBuilder(
                      valueListenable: _avatarUrlController,
                      builder: (context, value, _) {
                        return CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _avatarUrlController.text.isNotEmpty
                              ? NetworkImage(_avatarUrlController.text)
                              : null,
                          child: _avatarUrlController.text.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey,
                                )
                              : null,
                        );
                      },
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _avatarUrlController,
                decoration: const InputDecoration(
                  labelText: 'Avatar URL',
                  hintText: 'https://example.com/me.jpg',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ibanController,
                decoration: const InputDecoration(
                  labelText: 'IBAN',
                  hintText: 'DE12 3456...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _paymentInfoController,
                decoration: const InputDecoration(
                  labelText: 'Payment Info (PayPal / Venmo / Cash App)',
                  hintText: 'PayPal: me@example.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                  helperText:
                      'This will be shown to others when they owe you money.',
                  helperMaxLines: 2,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveProfile,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: _isLoading ? null : _deleteAccount,
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text(
                    'Delete Account',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
