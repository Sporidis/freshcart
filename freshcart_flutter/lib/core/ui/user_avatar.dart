import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/core/theme/hex_color_x.dart';

/// Renders one person's avatar: an uploaded photo if they have one,
/// otherwise a colour they chose, otherwise the deterministic colour hashed
/// from [seed] — in that order (`docs/decisions.md` #65). The same rule
/// applies everywhere someone's avatar shows, from a single widget, so a
/// drawer row and an Edit profile preview cannot drift out of sync with each
/// other about which of the three actually wins.
class UserAvatar extends StatefulWidget {
  /// Creates an avatar, resolving [photoUrl] and [color] against the
  /// [seed]-hashed fallback.
  const UserAvatar({
    required this.seed,
    required this.initial,
    this.photoUrl,
    this.color,
    this.radius = 18,
    this.border,
    super.key,
  });

  /// A stable id (a user's own) the hash fallback is derived from.
  final String seed;

  /// Shown when there is no photo to render — a member's initial, uppercase.
  final String initial;

  /// An uploaded avatar photo's URL, or `null` if the person has not set one.
  final String? photoUrl;

  /// A colour the person chose for their avatar, or `null` if they have not.
  final HexColor? color;

  /// The circle's radius.
  final double radius;

  /// An optional border -- the overlap "cutout" look an avatar stack draws
  /// around each avatar, in the surface colour behind it. `null` elsewhere.
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

  /// Today's existing behavior: a deterministic colour hashed from [seed].
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
