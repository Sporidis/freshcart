import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';

/// One person's avatar. Shows, in this order of preference:
/// 1. their photo, if they uploaded one;
/// 2. else the colour they picked;
/// 3. else a colour based on [seed] (always the same for the same person).
///
/// See decisions.md #65. Every avatar in the app uses this widget, so they
/// always look the same.
class UserAvatar extends StatefulWidget {
  /// Creates an avatar.
  const UserAvatar({
    required this.seed,
    required this.initial,
    this.photoUrl,
    this.color,
    this.radius = 18,
    this.border,
    super.key,
  });

  /// The user's id. Used to pick their default colour.
  final String seed;

  /// The letter shown when there's no photo.
  final String initial;

  /// An uploaded avatar photo's URL, or `null` if the person has not set one.
  final String? photoUrl;

  /// A colour the person chose for their avatar, or `null` if they have not.
  final HexColor? color;

  /// The circle's radius.
  final double radius;

  /// Optional border. `MemberAvatarStack` uses it so overlapping avatars
  /// look cut out from each other.
  final BoxBorder? border;

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  bool _imageFailed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.photoUrl != null && !_imageFailed) {
      return _bordered(
        CircleAvatar(
          radius: widget.radius,
          backgroundImage: NetworkImage(widget.photoUrl!),
          onBackgroundImageError: (_, _) {
            if (mounted) setState(() => _imageFailed = true);
          },
        ),
      );
    }
    if (widget.color != null) {
      return _bordered(
        CircleAvatar(
          radius: widget.radius,
          backgroundColor: widget.color!.toColor(),
          foregroundColor: Colors.white,
          child: Text(widget.initial, style: AppTextStyles.captionStrong),
        ),
      );
    }

    return _hashFallback(context);
  }

  /// The default: a colour based on [seed].
  Widget _hashFallback(BuildContext context) => _bordered(
    CircleAvatar(
      radius: widget.radius,
      backgroundColor: AppColors.avatarColorFor(widget.seed),
      foregroundColor: Colors.white,
      child: Text(widget.initial, style: AppTextStyles.captionStrong),
    ),
  );

  /// Wraps [child] with [border], if one was given.
  Widget _bordered(Widget child) {
    if (widget.border == null) return child;
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, border: widget.border),
      child: child,
    );
  }
}
