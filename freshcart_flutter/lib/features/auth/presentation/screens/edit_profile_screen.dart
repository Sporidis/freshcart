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

/// The screen where users edit their name, avatar colour and avatar photo.
///
/// Opened from the "Edit" link in Settings. Order from top to bottom:
/// avatar, colour, name.
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

  // "Saving..." flags and errors are kept here, not in the controller (see
  // EditProfileScreenState for why). Errors are stored as Failure and only
  // turned into text in build(), so they update if the language changes.
  Failure? _nameFailure;
  bool _savingName = false;

  // One flag for all avatar actions (colour, choose photo, remove photo).
  // The user can only do one at a time anyway.
  bool _busyAvatar = false;
  Failure? _avatarFailure;

  // The profile may still be loading in `initState`, so we can't fill in
  // the name there. Instead, `_seedNameOnce` fills it in the first time
  // build() has the profile.
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
    // If saving works, close the screen. If not, stay and show the error
    // under the field.
    if (failure == null) await Navigator.of(context).maybePop();
  }

  /// Runs one avatar action from the controller. This method only handles
  /// the busy flag and the error. The controller does the actual work.
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

    // If the profile couldn't load, show an error screen. Without a
    // profile there's no form to show, and the spinner would spin forever.
    final loadFailure = s.loadFailure;
    if (loadFailure != null) {
      return ErrorScreen(
        failure: loadFailure,
        t: t,
        onExit: () => Navigator.of(context).pop(),
      );
    }

    // Copied into a local variable, so Dart knows it's not null after the
    // check below.
    final user = s.user;
    if (user != null) _seedNameOnce(user.displayName);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.profile.title),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        // Save is in the top bar. It only saves the name: colour and photo
        // are saved immediately when picked.
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
                // The avatar letter updates while typing, so the preview
                // matches what others will see.
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

/// The "Choose photo" / "Remove photo" text buttons under the avatar.
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

/// The "Your colour on shared lists" picker, centred under the avatar.
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

  /// The name as typed right now (not the saved one).
  final String name;

  /// The biggest avatar in the app (88 px).
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
