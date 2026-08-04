import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../application/profile_controller.dart';
import '../domain/user_profile.dart';
import 'theme.dart';
import 'widgets/emoji_selector.dart';

class ProfileSetupScreen extends riverpod.ConsumerStatefulWidget {
  final String ownerId;
  final UserProfile? initialProfile;
  final Future<void> Function()? onComplete;
  final VoidCallback? onBack;

  const ProfileSetupScreen({
    required this.ownerId,
    super.key,
    this.initialProfile,
    this.onComplete,
    this.onBack,
  });

  @override
  riverpod.ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState
    extends riverpod.ConsumerState<ProfileSetupScreen> {
  late final TextEditingController _nameController;
  late String _selectedEmoji;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _nameController = TextEditingController(
      text: profile == null || profile.name == 'Mi espacio' ? '' : profile.name,
    );
    _selectedEmoji = profile?.avatarEmoji ?? '😊';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            if (widget.onBack != null)
              Positioned(
                left: 8,
                top: 8,
                child: IconButton(
                  key: const ValueKey('profile-setup-back'),
                  onPressed: _isSaving ? null : widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Volver',
                ),
              ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: AppTheme.cardGradient(colorScheme, isDark),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _selectedEmoji,
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Tu perfil',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nombre y avatar',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 40),
                      CompactAvatarPicker(
                        label: 'Avatar',
                        selectedEmoji: _selectedEmoji,
                        onTap: () async {
                          if (_isSaving) return;
                          final emoji = await showEmojiPickerSheet(
                            context: context,
                            selectedEmoji: _selectedEmoji,
                          );
                          if (emoji != null && mounted) {
                            setState(() => _selectedEmoji = emoji);
                          }
                        },
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        key: const ValueKey('profile-setup-name'),
                        controller: _nameController,
                        enabled: !_isSaving,
                        decoration: InputDecoration(
                          labelText: '¿Cómo te llamas?',
                          hintText: 'Tu nombre',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _saveProfile(),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const ValueKey('profile-setup-continue'),
                          onPressed: _isSaving ? null : _saveProfile,
                          icon: _isSaving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Continuar'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe tu nombre.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();
    try {
      final controller =
          ref.read(profileControllerProvider(widget.ownerId).notifier);
      if (widget.initialProfile == null) {
        await controller.createProfile(
          name: name,
          avatarEmoji: _selectedEmoji,
        );
      } else {
        await controller.updateProfile(
          name: name,
          avatarEmoji: _selectedEmoji,
        );
      }
      await widget.onComplete?.call();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos guardar tu perfil. Inténtalo de nuevo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
