import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/error_screen.dart';
import 'package:freshcart_flutter/core/ui/initial_for.dart';
import 'package:freshcart_flutter/core/ui/user_avatar.dart';
import 'package:freshcart_flutter/features/auth/application/edit_profile_screen/edit_profile_screen_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

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
  EditProfileScreenController get _vm =>
      ref.read(editProfileScreenControllerProvider.notifier);

  late final TextEditingController _nameController;

  // The saving flags and failures live here, not in the VM's state -- see
  // EditProfileScreenState for why. Failures stay as Failure and are only
  // turned into text in build, so a language switch re-translates them.
  Failure? _nameFailure;
  bool _savingName = false;

  // One flag for all three avatar actions (colour tap, photo pick, photo
  // remove): a person can only be doing one of them at a time, and they all
  // reach for the same preview, so there is nothing a single flag loses.
  bool _busyAvatar = false;
  Failure? _avatarFailure;

  // The profile is async — it has not necessarily resolved by the time
  // `initState` runs, so the field cannot be seeded from a synchronous
  // read here (it would just start empty and never catch up, since a
  // `TextEditingController` set once in `initState` does not react to a
  // later rebuild). Seeded instead the first time `build` actually sees a
  // value, in `_seedNameOnce`.
  bool _nameSeeded = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _seedNameOnce(String displayName) {
    if (_nameSeeded) return;
    _nameSeeded = true;
    _nameController.text = displayName;
  }

  Future<void> _saveName() async {
    setState(() {
      _savingName = true;
      _nameFailure = null;
    });
    final failure = await _vm.setDisplayName(_nameController.text);
    if (!mounted) return;
    setState(() {
      _savingName = false;
      _nameFailure = failure;
    });
  }

  /// Runs one avatar action from the VM, owning only the busy flag and the
  /// error beside it -- what the action *does* is the VM's business.
  Future<void> _runAvatarAction(
    Future<Failure?> Function() action,
  ) async {
    setState(() {
      _busyAvatar = true;
      _avatarFailure = null;
    });
    final failure = await action();
    if (!mounted) return;
    setState(() {
      _busyAvatar = false;
      _avatarFailure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final s = ref.watch(editProfileScreenControllerProvider);

    // A failed load is the screen tier here too (see list_settings_screen.dart's
    // identical guard): without a profile there is no form to show, so this
    // replaces the screen instead of leaving the spinner up forever.
    final loadFailure = s.loadFailure;
    if (loadFailure != null) {
      return ErrorScreen(
        failure: loadFailure,
        t: t,
        onExit: () => Navigator.of(context).pop(),
      );
    }

    // A local, not s.user, so the null check below promotes it.
    final user = s.user;
    if (user != null) _seedNameOnce(user.displayName);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.profile.title),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                _AvatarPreview(
                  user: user,
                ),
                const SizedBox(height: 24),
                _NameSection(
                  nameController: _nameController,
                  nameError: _nameFailure?.toMessage(t),
                  savingName: _savingName,
                  onSaveName: _saveName,
                  t: t,
                ),
                const SizedBox(height: 24),
                _AvatarSection(
                  user: user,
                  busyAvatar: _busyAvatar,
                  avatarFailure: _avatarFailure,
                  t: t,
                  onPickColor: (color) =>
                      _runAvatarAction(() => _vm.setAvatarColor(color)),
                  onChoosePhoto: () => _runAvatarAction(_vm.choosePhoto),
                  onRemovePhoto: () => _runAvatarAction(_vm.removePhoto),
                ),
              ],
            ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.user,
    required this.busyAvatar,
    required this.t,
    required this.onPickColor,
    required this.onChoosePhoto,
    required this.onRemovePhoto,
    required this.avatarFailure,
  });

  final AuthUser user;
  final bool busyAvatar;
  final Translations t;
  final ValueChanged<HexColor> onPickColor;
  final VoidCallback onChoosePhoto;
  final VoidCallback onRemovePhoto;
  final Failure? avatarFailure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        if (avatarFailure case final failure?) ...[
          const SizedBox(height: 10),
          Text(
            failure.toMessage(t),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.destructive,
            ),
          ),
        ],
      ],
    );
  }
}

class _NameSection extends StatelessWidget {
  const _NameSection({
    required this.nameController,
    required this.nameError,
    required this.savingName,
    required this.onSaveName,
    required this.t,
  });

  final String? nameError;
  final bool savingName;
  final VoidCallback onSaveName;
  final TextEditingController nameController;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.profile.nameLabel, style: theme.textTheme.bodySmall),
        const SizedBox(height: 10),
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
      ],
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.user,
  });

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final initial = initialFor(user.displayName);

    return Center(
      child: UserAvatar(
        seed: user.id.value,
        initial: initial,
        photoUrl: user.avatarPhotoUrl,
        color: user.avatarColor,
        radius: 40,
      ),
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
