import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/color_swatch_picker.dart';
import 'package:freshcart_flutter/core/ui/error_screen.dart';
import 'package:freshcart_flutter/core/ui/initial_for.dart';
import 'package:freshcart_flutter/core/ui/user_avatar.dart';
import 'package:freshcart_flutter/features/auth/application/edit_profile_screen/edit_profile_screen_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Edits the signed-in user's own profile: display name, avatar colour, and
/// an optional avatar photo.
///
/// Reached from the Settings profile header's Edit link (Flow 10). Laid out
/// the way the design orders it: the avatar first, since the household
/// recognises you by it, then its colour, then the name.
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
    // Save is the header's "done" action, so a successful one closes the
    // screen; a failed one stays, with its message inline on the field.
    if (failure == null) await Navigator.of(context).maybePop();
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
        // Save lives in the header (Flow 10): it only ever applies the name
        // -- colour and photo save the moment they are picked -- so it is a
        // "done with the name" action, not a form submit at the bottom.
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.gapSmall),
              child: TextButton(
                onPressed: _savingName ? null : _saveName,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  textStyle: AppTextStyles.labelStrong,
                ),
                child: Text(t.common.save),
              ),
            ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                // The avatar follows the name field as it is typed, so the
                // preview is always what the household will actually see.
                ValueListenableBuilder(
                  valueListenable: _nameController,
                  builder: (context, value, _) =>
                      _AvatarPreview(user: user, name: value.text),
                ),
                _PhotoActions(
                  user: user,
                  busy: _busyAvatar,
                  t: t,
                  onChoosePhoto: () => _runAvatarAction(_vm.choosePhoto),
                  onRemovePhoto: () => _runAvatarAction(_vm.removePhoto),
                ),
                const SizedBox(height: AppSpacing.gap),
                _ColorSection(
                  user: user,
                  busy: _busyAvatar,
                  failure: _avatarFailure,
                  t: t,
                  onPickColor: (color) =>
                      _runAvatarAction(() => _vm.setAvatarColor(color)),
                ),
                const SizedBox(height: AppSpacing.screen),
                _NameSection(
                  nameController: _nameController,
                  nameError: _nameFailure?.toMessage(t),
                  savingName: _savingName,
                  onSaveName: _saveName,
                  t: t,
                ),
              ],
            ),
    );
  }
}

/// Choose / remove photo, as quiet text actions directly under the avatar
/// they change -- the photo is part of the avatar, not a separate form
/// section competing with the name.
class _PhotoActions extends StatelessWidget {
  const _PhotoActions({
    required this.user,
    required this.busy,
    required this.t,
    required this.onChoosePhoto,
    required this.onRemovePhoto,
  });

  final AuthUser user;
  final bool busy;
  final Translations t;
  final VoidCallback onChoosePhoto;
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final style = TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.primary,
      textStyle: AppTextStyles.labelStrong,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: busy ? null : onChoosePhoto,
          style: style,
          child: Text(t.profile.choosePhoto),
        ),
        if (user.avatarPhotoUrl != null)
          TextButton(
            onPressed: busy ? null : onRemovePhoto,
            style: style,
            child: Text(t.profile.removePhoto),
          ),
      ],
    );
  }
}

/// "Your colour on shared lists": centred under the avatar it recolours,
/// as in the design, so cause and effect sit on one axis.
class _ColorSection extends StatelessWidget {
  const _ColorSection({
    required this.user,
    required this.busy,
    required this.failure,
    required this.t,
    required this.onPickColor,
  });

  final AuthUser user;
  final bool busy;
  final Failure? failure;
  final Translations t;
  final ValueChanged<HexColor> onPickColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = user.avatarColor;
    return Column(
      children: [
        Text(t.profile.colorLabel, style: theme.textTheme.bodySmall),
        const SizedBox(height: AppSpacing.gapSmall),
        ColorSwatchPicker(
          colors: AppColors.presetShopColors,
          selected: current == null ? null : Color(current.argb),
          alignment: WrapAlignment.center,
          keyPrefix: 'avatar-swatch-',
          semanticLabel: t.profile.colorLabel,
          onSelected: busy
              ? null
              : (color) => onPickColor(HexColor.fromArgb(color.toARGB32())),
        ),
        if (failure case final failure?) ...[
          const SizedBox(height: AppSpacing.gapSmall),
          Text(
            failure.toMessage(t),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
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
        const SizedBox(height: AppSpacing.gapSmall),
        TextField(
          controller: nameController,
          enabled: !savingName,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSaveName(),
          decoration: InputDecoration(errorText: nameError),
        ),
        const SizedBox(height: AppSpacing.gapSmall),
        Text(t.profile.nameHelper, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.user, required this.name});

  final AuthUser user;

  /// The name as currently typed, not as saved -- see the builder above.
  final String name;

  /// The design's 88 px profile avatar: the largest one in the app, since
  /// this is the one screen that is *about* it.
  static const double _size = 88;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: UserAvatar(
        seed: user.id.value,
        initial: initialFor(name),
        photoUrl: user.avatarPhotoUrl,
        color: user.avatarColor,
        radius: _size / 2,
      ),
    );
  }
}
