import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/error_screen.dart';
import 'package:freshcart_flutter/core/ui/user_avatar.dart';
import 'package:freshcart_flutter/features/auth/application/profile_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:image_picker/image_picker.dart';

/// Edits the signed-in user's own profile: display name, avatar colour, and
/// an optional avatar photo.
///
/// Temporarily reached from [SettingsScreen] — its real home, a profile row
/// on a restructured Settings screen, is a later build-order item
/// (`docs/design-gap-plan.md` §5). This screen and its route exist now so the
/// feature is actually usable in the meantime rather than stranded behind a
/// navigation change that has not landed yet (`docs/decisions.md` #66).
class EditProfileScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name;
  String? _nameError;
  bool _savingName = false;

  // One flag for all three avatar actions (colour tap, photo pick, photo
  // remove): a person can only be doing one of them at a time, and they all
  // reach for the same preview, so there is nothing a single flag loses.
  bool _busyAvatar = false;
  String? _avatarError;

  // `profileControllerProvider` is async — it has not necessarily resolved by the
  // time `initState` runs, so the field cannot be seeded from a synchronous
  // read here (it would just start empty and never catch up, since a
  // `TextEditingController` set once in `initState` does not react to a
  // later rebuild). Seeded instead the first time `build` actually sees a
  // value, in `_seedNameOnce`.
  bool _nameSeeded = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _seedNameOnce(String displayName) {
    if (_nameSeeded) return;
    _nameSeeded = true;
    _name.text = displayName;
  }

  Future<void> _saveName() async {
    setState(() {
      _savingName = true;
      _nameError = null;
    });
    final failure = await _profile.setDisplayName(_name.text);
    if (!mounted) return;
    setState(() {
      _savingName = false;
      _nameError = failure?.toMessage(ref.read(translationsProvider));
    });
  }

  ProfileController get _profile =>
      ref.read(profileControllerProvider.notifier);

  Future<void> _pickColor(HexColor color) =>
      _runAvatarAction(() => _profile.setAvatarColor(color));

  Future<void> _choosePhoto() async {
    // Picking and reading the file happen outside `_runAvatarAction`'s own
    // try/catch-free `action()` call, and can throw a native/platform
    // exception (denied file-access permission, or no image_picker
    // implementation on this platform at all) rather than return a `Result`
    // — so it needs its own guard, or it dies as a silent unhandled Future
    // error with nothing shown in the UI.
    final XFile? picked;
    final Uint8List bytes;
    try {
      picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        // Downsized on pick: a raw camera photo can run to several MB, far
        // more than an avatar needs — the server's own size cap
        // (`ProfileService.maxAvatarPhotoBytes`) is a backstop for a client
        // that skipped this, not the size a normal upload is meant to reach.
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;
      bytes = await picked.readAsBytes();
    } on Object {
      if (!mounted) return;
      setState(
        () => _avatarError = ref.read(translationsProvider).errors.unexpected,
      );
      return;
    }

    if (!mounted) return;
    await _runAvatarAction(() => _profile.setAvatarPhoto(bytes));
  }

  Future<void> _removePhoto() => _runAvatarAction(_profile.clearAvatarPhoto);

  Future<void> _runAvatarAction(
    Future<Failure?> Function() action,
  ) async {
    setState(() {
      _busyAvatar = true;
      _avatarError = null;
    });
    final failure = await action();
    if (!mounted) return;
    setState(() {
      _busyAvatar = false;
      _avatarError = failure?.toMessage(ref.read(translationsProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final user = ref.watch(profileControllerProvider);

    // A failed load is the screen tier here too (see list_settings_screen.dart's
    // identical guard): without a profile there is no form to show, so this
    // replaces the screen instead of leaving loaded == null spinning forever.
    final failure = user.loadFailure;
    if (failure != null) {
      return ErrorScreen(
        failure: failure,
        t: t,
        onExit: () => Navigator.of(context).pop(),
      );
    }

    final loaded = user.dataOrNull;
    if (loaded != null) _seedNameOnce(loaded.displayName);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.profile.title),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: loaded == null
          ? const Center(child: CircularProgressIndicator())
          : _ProfileForm(
              user: loaded,
              t: t,
              nameController: _name,
              nameError: _nameError,
              savingName: _savingName,
              onSaveName: _saveName,
              busyAvatar: _busyAvatar,
              avatarError: _avatarError,
              onPickColor: _pickColor,
              onChoosePhoto: _choosePhoto,
              onRemovePhoto: _removePhoto,
            ),
    );
  }
}

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({
    required this.user,
    required this.t,
    required this.nameController,
    required this.nameError,
    required this.savingName,
    required this.onSaveName,
    required this.busyAvatar,
    required this.avatarError,
    required this.onPickColor,
    required this.onChoosePhoto,
    required this.onRemovePhoto,
  });

  final AuthUser user;
  final Translations t;
  final TextEditingController nameController;
  final String? nameError;
  final bool savingName;
  final VoidCallback onSaveName;
  final bool busyAvatar;
  final String? avatarError;
  final ValueChanged<HexColor> onPickColor;
  final VoidCallback onChoosePhoto;
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = user.displayName.trim().isEmpty
        ? '?'
        : user.displayName.trim()[0].toUpperCase();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        Center(
          child: UserAvatar(
            seed: user.id.value,
            initial: initial,
            photoUrl: user.avatarPhotoUrl,
            color: user.avatarColor,
            radius: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(t.profile.nameLabel, style: theme.textTheme.bodySmall),
        const SizedBox(height: 6),
        TextField(
          controller: nameController,
          enabled: !savingName,
          decoration: InputDecoration(errorText: nameError),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: savingName ? null : onSaveName,
            child: Text(t.common.save),
          ),
        ),
        const SizedBox(height: 24),
        Text(t.profile.colorLabel, style: theme.textTheme.bodySmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final swatch in AppColors.presetShopColors)
              _ColorSwatch(
                key: ValueKey('avatar-swatch-${swatch.toARGB32()}'),
                color: swatch,
                selected: user.avatarColor?.argb == swatch.toARGB32(),
                onTap: busyAvatar
                    ? null
                    : () => onPickColor(HexColor.fromArgb(swatch.toARGB32())),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(t.profile.photoLabel, style: theme.textTheme.bodySmall),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: busyAvatar ? null : onChoosePhoto,
                child: Text(t.profile.choosePhoto),
              ),
            ),
            if (user.avatarPhotoUrl != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: busyAvatar ? null : onRemovePhoto,
                  child: Text(t.profile.removePhoto),
                ),
              ),
            ],
          ],
        ),
        if (avatarError != null) ...[
          const SizedBox(height: 10),
          Text(
            avatarError!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.destructive,
            ),
          ),
        ],
      ],
    );
  }
}

/// A single tappable colour circle — the same shape `EditShopSheet`'s own
/// swatch picker uses, kept as its own small copy rather than a shared
/// import across features for one widget this size.
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: selected ? Border.all(color: ink, width: 2.5) : null,
          ),
          child: selected
              ? const Center(
                  child: SizedBox(
                    width: 10,
                    height: 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
