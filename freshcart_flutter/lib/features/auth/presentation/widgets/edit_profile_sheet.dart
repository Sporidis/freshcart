import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/core/ui/avatar/initial_for.dart';
import 'package:freshcart_flutter/core/ui/avatar/user_avatar.dart';
import 'package:freshcart_flutter/core/ui/color_swatch_picker.dart';
import 'package:freshcart_flutter/core/ui/sheet/app_sheet.dart';
import 'package:freshcart_flutter/features/auth/application/edit_profile_sheet/edit_profile_sheet_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Opens [EditProfileSheet]. Used by the drawer header and by Settings.
Future<void> showEditProfileSheet(BuildContext context) => showAppSheet<void>(
  context: context,
  builder: (_) => const EditProfileSheet(),
);

/// Design v3: edit your profile in a sheet. A 76px avatar, the name, the
/// avatar colour, and Save.
///
/// The colour and photo are saved the moment they're picked, as before.
/// Save only saves the name, then closes the sheet.
///
/// It was a pushed screen. It became a sheet because it's a quick side
/// task you come back from, not a place you go (decisions.md #106).
class EditProfileSheet extends ConsumerStatefulWidget {
  /// Creates the sheet.
  const EditProfileSheet({super.key});

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  EditProfileSheetController get _vm =>
      ref.read(editProfileSheetControllerProvider.notifier);

  late final TextEditingController _nameController;

  // "Saving..." flags and errors are kept here, not in the controller (see
  // EditProfileSheetState for why). Errors are stored as Failure and only
  // turned into text in build(), so they update if the language changes.
  Failure? _nameFailure;
  bool _savingName = false;

  // One flag for all avatar actions (colour, choose photo, remove photo).
  // The user can only do one at a time anyway.
  bool _busyAvatar = false;
  Failure? _avatarFailure;

  // The profile may still be loading in `initState`, so the name is filled
  // in the first time build() has the profile.
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
    // If saving works, close the sheet. If not, stay and show the error
    // under the field.
    if (failure == null) await Navigator.of(context).maybePop();
  }

  /// Runs one avatar action from the controller. This method only handles
  /// the busy flag and the error. The controller does the actual work.
  Future<void> _runAvatarAction(Future<Failure?> Function() action) async {
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
    final s = ref.watch(editProfileSheetControllerProvider);
    final theme = Theme.of(context);

    // Copied into a local variable, so Dart knows it's not null after the
    // check below.
    final user = s.user;
    if (user != null) _seedNameOnce(user.displayName);

    final loadFailure = s.loadFailure;
    if (user == null) {
      // No profile, no form. A sheet is small, so the error is a line of
      // text instead of a full error screen; the × still closes it.
      return AppSheetScaffold(
        title: t.profile.title,
        children: [
          SizedBox(
            height: 120,
            child: Center(
              child: loadFailure == null
                  ? const CircularProgressIndicator()
                  : Text(
                      loadFailure.toMessage(t),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
            ),
          ),
        ],
      );
    }

    return AppSheetScaffold(
      title: t.profile.title,
      children: [
        // The avatar letter updates while typing, so the preview matches
        // what others will see.
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
        const SizedBox(height: AppSpacing.sm),
        _FieldLabel(t.profile.nameLabel),
        TextField(
          controller: _nameController,
          enabled: !_savingName,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _saveName(),
          decoration: InputDecoration(
            errorText: _nameFailure?.toMessage(t),
            helperText: t.profile.nameHelper,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _FieldLabel(t.profile.colorLabel),
        _ColorRow(
          user: user,
          busy: _busyAvatar,
          failure: _avatarFailure,
          t: t,
          onPickColor: (color) =>
              _runAvatarAction(() => _vm.setAvatarColor(color)),
        ),
        const SizedBox(height: AppSpacing.xl),
        // Disabled while the name is empty: an empty name can't be saved
        // anyway, so the button says so instead of failing.
        ValueListenableBuilder(
          valueListenable: _nameController,
          builder: (context, value, _) => ElevatedButton(
            onPressed: _savingName || value.text.trim().isEmpty
                ? null
                : _saveName,
            child: Text(t.common.save),
          ),
        ),
      ],
    );
  }
}

/// The 13/600 muted label above a field, as in v3.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      text,
      style: AppTextStyles.captionStrong.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

/// The "Choose photo" / "Remove photo" links under the avatar.
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
      foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
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

/// The avatar colours, spread across the sheet's width (v3), with the
/// error under them if saving one failed.
class _ColorRow extends StatelessWidget {
  const _ColorRow({
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColorSwatchPicker(
          colors: AppColors.presetShopColors,
          selected: current?.toColor(),
          alignment: WrapAlignment.spaceBetween,
          keyPrefix: 'avatar-swatch-',
          semanticLabel: t.profile.colorLabel,
          onSelected: busy
              ? null
              : (color) => onPickColor(HexColor.fromArgb(color.toARGB32())),
        ),
        if (failure case final failure?) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            failure.toMessage(t),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

/// The 76px avatar at the top, with the v3 soft shadow.
class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.user, required this.name});

  final AuthUser user;

  /// The name as typed right now (not the saved one).
  final String name;

  static const double _size = 76;

  @override
  Widget build(BuildContext context) => Center(
    child: DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x24000000), // black 14%
            offset: Offset(0, 8),
            blurRadius: 22,
          ),
        ],
      ),
      child: UserAvatar(
        seed: user.id.value,
        initial: initialFor(name),
        photoUrl: user.avatarPhotoUrl,
        color: user.avatarColor,
        radius: _size / 2,
      ),
    ),
  );
}
