// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/features/user_profile/application/user_profile_repository_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Widget de sélection, compression et upload d'avatar.
///
/// Affiche un avatar circulaire (image ou initiales en fallback).
/// Tap long : menu "Changer" / "Supprimer".
class AvatarPicker extends ConsumerStatefulWidget {
  final String? currentAvatarUrl;
  final String userInitials;
  final VoidCallback? onUploadSuccess;

  const AvatarPicker({
    super.key,
    required this.currentAvatarUrl,
    required this.userInitials,
    this.onUploadSuccess,
  });

  @override
  ConsumerState<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends ConsumerState<AvatarPicker> {
  bool _isLoading = false;
  String? _errorMessage;

  // Taille cible côté client : 1.5 MB (< limite serveur 2 MB)
  static const int _targetSizeKb = 1536;

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final compressed = await _compressImage(picked.path);
      final repo =
          await ref.read(userProfileRepositoryProvider.future);
      await repo.uploadAvatar(compressed ?? File(picked.path));
      widget.onUploadSuccess?.call();
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _mapError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<File?> _compressImage(String sourcePath) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/avatar_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      targetPath,
      quality: 85,
      minWidth: 256,
      minHeight: 256,
      format: CompressFormat.jpeg,
    );

    if (result == null) return null;

    final file = File(result.path);
    final sizeKb = await file.length() ~/ 1024;

    // Si toujours > cible, recompresser avec qualité 60
    if (sizeKb > _targetSizeKb) {
      final targetPath2 =
          '${dir.path}/avatar_compressed2_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result2 = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        targetPath2,
        quality: 60,
        minWidth: 256,
        minHeight: 256,
        format: CompressFormat.jpeg,
      );
      if (result2 != null) return File(result2.path);
    }

    return file;
  }

  Future<void> _deleteAvatar() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repo =
          await ref.read(userProfileRepositoryProvider.future);
      await repo.deleteAvatar();
      widget.onUploadSuccess?.call();
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _mapError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAvatarMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const PhosphorIcon(PhosphorIconsRegular.camera),
              title: const Text('Changer la photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload();
              },
            ),
            if (widget.currentAvatarUrl != null)
              ListTile(
                leading: PhosphorIcon(
                  PhosphorIconsRegular.trash,
                  color: Theme.of(ctx).colorScheme.error,
                ),
                title: Text(
                  'Supprimer la photo',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteAvatar();
                },
              ),
            ListTile(
              leading: const PhosphorIcon(PhosphorIconsRegular.x),
              title: const Text('Annuler'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  String _mapError(Exception e) {
    final msg = e.toString();
    if (msg.contains('413') || msg.contains('FILE_TOO_LARGE')) {
      return 'Image trop lourde (max 2 MB)';
    }
    if (msg.contains('400') || msg.contains('INVALID_IMAGE_FORMAT')) {
      return 'Format invalide — JPG ou PNG uniquement';
    }
    return 'Erreur lors de l\'upload';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        GestureDetector(
          onTap: _isLoading ? null : _pickAndUpload,
          onLongPress: _isLoading ? null : () => _showAvatarMenu(context),
          child: Stack(
            alignment: Alignment.center,
            children: [
              _AvatarCircle(
                avatarUrl: widget.currentAvatarUrl,
                initials: widget.userInitials,
                radius: 48,
              ),
              if (_isLoading)
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gray900.withValues(alpha: 0.4),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.gray50,
                    ),
                  ),
                ),
              if (!_isLoading)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: PhosphorIcon(
                      PhosphorIconsRegular.camera,
                      size: 14,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            _errorMessage!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.space2),
        TextButton(
          onPressed: _isLoading ? null : () => _showAvatarMenu(context),
          child: const Text('Modifier la photo'),
        ),
      ],
    );
  }
}

/// Cercle avatar — image réseau si URL fournie, sinon initiales.
class _AvatarCircle extends StatelessWidget {
  final String? avatarUrl;
  final String initials;
  final double radius;

  const _AvatarCircle({
    required this.avatarUrl,
    required this.initials,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl!),
        onBackgroundImageError: (e, _) {},
        child: null,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        initials.length > 2 ? initials.substring(0, 2).toUpperCase() : initials.toUpperCase(),
        style: theme.textTheme.headlineSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Widget public réutilisable pour afficher un avatar (lecture seule).
class AvatarCircle extends StatelessWidget {
  final String? avatarUrl;
  final String initials;
  final double radius;

  const AvatarCircle({
    super.key,
    required this.avatarUrl,
    required this.initials,
    this.radius = AppRadius.round,
  });

  @override
  Widget build(BuildContext context) {
    return _AvatarCircle(
      avatarUrl: avatarUrl,
      initials: initials,
      radius: radius,
    );
  }
}
