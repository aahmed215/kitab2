// ═══════════════════════════════════════════════════════════════════
// EDIT_PROFILE_SCREEN.DART — Edit Profile Form
// First name, last name (optional), username (30-day cooldown),
// bio (250 chars), birthday (13+ check), email, password change,
// avatar upload, member since display.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/database_providers.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/kitab_theme.dart';
import '../../core/utils/content_filter.dart';
import '../../core/widgets/kitab_toast.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  String? _email;
  DateTime? _birthday;
  DateTime? _createdAt;
  String? _avatarUrl;
  bool _saving = false;
  bool _loaded = false;

  // Username editing
  String? _usernameError;
  String? _usernameSuccess;
  bool _editingUsername = false;
  String _originalUsername = '';
  DateTime? _usernameChangedAt;
  bool _checkingUsername = false;

  // Birthday validation
  String? _birthdayError;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (_loaded) return;
    _loaded = true;

    try {
      final userId = ref.read(currentUserIdProvider);
      final authUser = Supabase.instance.client.auth.currentUser;
      final metadata = authUser?.userMetadata;

      // Load from public.users
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (mounted) {
        final username = response?['username'] as String?
            ?? metadata?['username'] as String?
            ?? '';
        setState(() {
          _firstNameController.text = response?['name'] as String?
              ?? metadata?['name'] as String?
              ?? '';
          _lastNameController.text = response?['last_name'] as String? ?? '';
          _usernameController.text = username;
          _originalUsername = username;
          _usernameChangedAt = response?['username_changed_at'] != null
              ? DateTime.tryParse(response!['username_changed_at'] as String)
              : null;
          _bioController.text = response?['bio'] as String? ?? '';
          _birthday = response?['birthday'] != null
              ? DateTime.tryParse(response!['birthday'] as String)
              : null;
          _avatarUrl = response?['avatar_url'] as String?;
          _email = authUser?.email;
          _createdAt = response?['created_at'] != null
              ? DateTime.tryParse(response!['created_at'] as String)
              : authUser?.createdAt != null
                  ? DateTime.tryParse(authUser!.createdAt)
                  : null;
        });
      }
    } catch (e) {
      final authUser = Supabase.instance.client.auth.currentUser;
      if (mounted) {
        setState(() {
          _firstNameController.text = authUser?.userMetadata?['name'] as String? ?? '';
          _email = authUser?.email;
        });
      }
    }
  }

  /// Check if username change is within the 30-day cooldown.
  bool get _usernameOnCooldown {
    if (_usernameChangedAt == null) return false;
    return DateTime.now().difference(_usernameChangedAt!).inDays < 30;
  }

  int get _usernameCooldownDaysLeft {
    if (_usernameChangedAt == null) return 0;
    return 30 - DateTime.now().difference(_usernameChangedAt!).inDays;
  }

  @override
  Widget build(BuildContext context) {
    _loadProfile();

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: KitabTypography.h2),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.all(KitabSpacing.lg),
            children: [
              // ─── Avatar ───
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _showAvatarOptions,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: KitabColors.primary.withValues(alpha: 0.1),
                            backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                            child: _avatarUrl == null
                                ? Text(
                                    _firstNameController.text.isNotEmpty
                                        ? _firstNameController.text[0].toUpperCase()
                                        : '?',
                                    style: KitabTypography.display.copyWith(
                                        color: KitabColors.primary, fontSize: 40),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: KitabColors.primary, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Member Since ───
              if (_createdAt != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: KitabSpacing.sm),
                    child: Text(
                      'Member Since: ${ref.watch(dateFormatterProvider).monthYear(_createdAt!)}',
                      style: KitabTypography.caption.copyWith(color: KitabColors.gray500),
                    ),
                  ),
                ),
              const SizedBox(height: KitabSpacing.xl),

              // ─── First Name ───
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name', prefixIcon: Icon(Icons.person_outline)),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: KitabSpacing.md),

              // ─── Last Name (optional) ───
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name (optional)',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: KitabSpacing.md),

              // ─── Username (30-day cooldown) ───
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(Icons.alternate_email),
                  helperText: _editingUsername
                      ? '3-20 chars, letters, numbers, underscores'
                      : null,
                  helperMaxLines: 2,
                  errorText: _usernameError,
                  suffixIcon: _editingUsername
                      ? (_checkingUsername
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2)))
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() {
                                _editingUsername = false;
                                _usernameController.text = _originalUsername;
                                _usernameError = null;
                                _usernameSuccess = null;
                              }),
                            ))
                      : IconButton(
                          icon: const Icon(Icons.edit, size: 18, color: KitabColors.gray400),
                          onPressed: () {
                            if (_usernameOnCooldown) {
                              setState(() {
                                _usernameError = 'You can change your username in $_usernameCooldownDaysLeft days';
                              });
                            } else {
                              setState(() => _editingUsername = true);
                            }
                          },
                        ),
                ),
                readOnly: !_editingUsername,
                autocorrect: false,
                onChanged: _onUsernameChanged,
              ),
              // Inline cooldown notice when editing
              if (_editingUsername && !_usernameOnCooldown)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 2),
                  child: Text(
                    'You can change your username once every 30 days.',
                    style: KitabTypography.caption.copyWith(color: KitabColors.warning),
                  ),
                ),
              if (_usernameSuccess != null)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 2),
                  child: Text(_usernameSuccess!,
                      style: KitabTypography.caption.copyWith(color: KitabColors.success)),
                ),
              const SizedBox(height: KitabSpacing.md),

              // ─── Bio (250 chars) ───
              TextField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Bio', prefixIcon: Icon(Icons.info_outline)),
                maxLength: 250,
                maxLines: 3,
              ),
              const SizedBox(height: KitabSpacing.md),

              // ─── Birthday (13+ check) ───
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cake_outlined),
                title: const Text('Birthday'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_birthday != null ? ref.watch(dateFormatterProvider).fullDate(_birthday!) : 'Not set'),
                    if (_birthdayError != null)
                      Text(_birthdayError!, style: TextStyle(color: KitabColors.error, fontSize: 12)),
                  ],
                ),
                trailing: const Icon(Icons.edit, size: 18, color: KitabColors.gray400),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _birthday ?? DateTime(2000, 1, 1),
                    firstDate: DateTime(1920),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    final age = DateTime.now().difference(picked).inDays ~/ 365;
                    setState(() {
                      _birthday = picked;
                      _birthdayError = age < 13 ? 'You must be at least 13 years old' : null;
                    });
                  }
                },
              ),
              const Divider(),

              // ─── Email ───
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                subtitle: Text(_email ?? 'Not set'),
                trailing: const Icon(Icons.edit, size: 18, color: KitabColors.gray400),
                onTap: _changeEmail,
              ),

              // ─── Password ───
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_outlined),
                title: const Text('Password'),
                subtitle: const Text('••••••••'),
                trailing: const Icon(Icons.edit, size: 18, color: KitabColors.gray400),
                onTap: _changePassword,
              ),

              const SizedBox(height: KitabSpacing.xl),

              // ─── Save ───
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Profile'),
                ),
              ),

              const SizedBox(height: KitabSpacing.xxl),
              const Divider(),
              const SizedBox(height: KitabSpacing.lg),

              // ─── Delete Account ───
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _deleteAccount,
                  icon: const Icon(Icons.delete_forever, color: KitabColors.error),
                  label: const Text('Delete Account', style: TextStyle(color: KitabColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: KitabColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: KitabSpacing.sm),
              Text(
                'This permanently deletes your cloud data. Local data on your devices is preserved.',
                style: KitabTypography.caption.copyWith(color: KitabColors.gray400),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KitabSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Username live check ───
  void _onUsernameChanged(String value) async {
    final username = value.trim();
    setState(() { _usernameError = null; _usernameSuccess = null; });

    if (username == _originalUsername || username.isEmpty) return;

    // Format check
    final regex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    if (!regex.hasMatch(username)) {
      setState(() => _usernameError = username.length < 3
          ? 'Too short (min 3 characters)'
          : 'Only letters, numbers, and underscores');
      return;
    }

    // Content filter: reserved names + profanity/slurs/extremist
    final contentCheck = ContentFilter.checkUsername(username);
    if (!contentCheck.isClean) {
      setState(() => _usernameError = contentCheck.reason);
      return;
    }

    setState(() => _checkingUsername = true);
    try {
      final available = await ref.read(userRepositoryProvider).isUsernameAvailable(username);
      if (mounted) {
        setState(() {
          _checkingUsername = false;
          if (available) {
            _usernameSuccess = 'Available ✓';
            _usernameError = null;
          } else {
            _usernameError = 'Username taken';
            _usernameSuccess = null;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checkingUsername = false);
    }
  }

  // ─── Change Email ───
  void _changeEmail() {
    final controller = TextEditingController(text: _email ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('A verification link will be sent to the new email.'),
            const SizedBox(height: KitabSpacing.md),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'New Email'),
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final newEmail = controller.text.trim();
              if (newEmail.isEmpty || newEmail == _email) return;
              try {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(email: newEmail),
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  KitabToast.success(context, 'Verification sent to new email');
                }
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  KitabToast.error(context, 'Error: $e');
                }
              }
            },
            child: const Text('Send Verification'),
          ),
        ],
      ),
    );
  }

  // ─── Change Password ───
  void _changePassword() {
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newController,
              decoration: const InputDecoration(labelText: 'New Password', helperText: 'At least 8 characters'),
              obscureText: true,
            ),
            const SizedBox(height: KitabSpacing.md),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(labelText: 'Confirm New Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final newPw = newController.text;
              final confirmPw = confirmController.text;
              if (newPw.length < 8) {
                KitabToast.error(context, 'Password must be at least 8 characters');
                return;
              }
              if (newPw != confirmPw) {
                KitabToast.error(context, 'Passwords do not match');
                return;
              }
              try {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(password: newPw),
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  KitabToast.success(context, 'Password updated');
                }
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  KitabToast.error(context, 'Error: $e');
                }
              }
            },
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
  }

  // ─── Delete Account ───
  void _deleteAccount() {
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final typed = confirmController.text.trim();
          final canDelete = typed == 'DELETE';

          return AlertDialog(
            title: const Text('Delete Account'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This action is permanent and cannot be undone.'),
                const SizedBox(height: KitabSpacing.md),
                Text('What happens:', style: KitabTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: KitabSpacing.xs),
                Text('• All your cloud data will be permanently deleted',
                    style: KitabTypography.bodySmall),
                Text('• Your account and login will be removed',
                    style: KitabTypography.bodySmall),
                Text('• Local data on your devices will be preserved',
                    style: KitabTypography.bodySmall),
                const SizedBox(height: KitabSpacing.lg),
                Text('Type DELETE to confirm:', style: KitabTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: KitabSpacing.xs),
                TextField(
                  controller: confirmController,
                  decoration: const InputDecoration(hintText: 'DELETE'),
                  onChanged: (_) => setDialogState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: canDelete ? KitabColors.error : KitabColors.gray300),
                onPressed: canDelete
                    ? () async {
                        Navigator.pop(ctx);
                        try {
                          await ref.read(authServiceProvider).deleteAccount();
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const KitabApp()),
                              (_) => false,
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            KitabToast.error(context, 'Error deleting account: $e');
                          }
                        }
                      }
                    : null,
                child: const Text('Delete Account'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Avatar ───
  /// Show options: change photo or remove photo.
  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: KitabSpacing.md),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAvatar();
              },
            ),
            if (_avatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: KitabColors.error),
                title: const Text('Remove Photo', style: TextStyle(color: KitabColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _removeAvatar();
                },
              ),
            const SizedBox(height: KitabSpacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
    if (image == null) return;

    try {
      final userId = ref.read(currentUserIdProvider);
      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last;
      final path = '$userId/avatar.$ext';

      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));

      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(path);

      // Append cache-buster so Flutter doesn't show the old cached image
      final cacheBusted = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      setState(() => _avatarUrl = cacheBusted);
    } catch (e) {
      if (mounted) {
        KitabToast.error(context, 'Failed to upload photo: $e');
      }
    }
  }

  Future<void> _removeAvatar() async {
    try {
      final userId = ref.read(currentUserIdProvider);

      // Delete from storage (try common extensions)
      for (final ext in ['jpg', 'jpeg', 'png', 'webp', 'gif']) {
        try {
          await Supabase.instance.client.storage
              .from('avatars')
              .remove(['$userId/avatar.$ext']);
        } catch (_) {}
      }

      // Clear URL in database
      await Supabase.instance.client
          .from('users')
          .update({'avatar_url': null, 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', userId);

      setState(() => _avatarUrl = null);

      if (mounted) {
        KitabToast.success(context, 'Photo removed');
      }
    } catch (e) {
      if (mounted) {
        KitabToast.error(context, 'Failed to remove photo: $e');
      }
    }
  }

  // ─── Save ───
  Future<void> _save() async {
    // Content filter check on name, last name, and bio
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final bio = _bioController.text.trim();

    final nameCheck = ContentFilter.check(firstName);
    if (!nameCheck.isClean) {
      KitabToast.error(context, 'First Name: ${nameCheck.reason}');
      return;
    }

    final lastNameCheck = ContentFilter.check(lastName);
    if (!lastNameCheck.isClean) {
      KitabToast.error(context, 'Last Name: ${lastNameCheck.reason}');
      return;
    }

    final bioCheck = ContentFilter.check(bio);
    if (!bioCheck.isClean) {
      KitabToast.error(context, 'Bio: ${bioCheck.reason}');
      return;
    }

    // Birthday age check
    if (_birthday != null) {
      final age = DateTime.now().difference(_birthday!).inDays ~/ 365;
      if (age < 13) {
        setState(() => _birthdayError = 'You must be at least 13 years old');
        return;
      }
    }

    final username = _usernameController.text.trim();
    final usernameChanged = username != _originalUsername;

    // Username validation
    if (usernameChanged && username.isNotEmpty) {
      if (_usernameOnCooldown) {
        setState(() => _usernameError = 'You can change your username in $_usernameCooldownDaysLeft days');
        return;
      }
      final regex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
      if (!regex.hasMatch(username)) {
        setState(() => _usernameError = 'Invalid format');
        return;
      }
      final available = await ref.read(userRepositoryProvider).isUsernameAvailable(username);
      if (!available) {
        setState(() => _usernameError = 'Username taken');
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final userId = ref.read(currentUserIdProvider);
      final now = DateTime.now();

      final updates = <String, dynamic>{
        'name': _firstNameController.text.trim().isEmpty ? null : _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim().isEmpty ? null : _lastNameController.text.trim(),
        'bio': _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        'avatar_url': _avatarUrl,
        'birthday': _birthday?.toIso8601String().split('T')[0],
        'updated_at': now.toUtc().toIso8601String(),
      };

      if (usernameChanged && username.isNotEmpty) {
        updates['username'] = username;
        updates['username_changed_at'] = now.toUtc().toIso8601String();
      }

      await Supabase.instance.client
          .from('users')
          .update(updates)
          .eq('id', userId);

      if (mounted) {
        Navigator.pop(context);
        KitabToast.success(context, 'Profile saved');
      }
    } catch (e) {
      if (mounted) {
        KitabToast.error(context, 'Error saving: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
