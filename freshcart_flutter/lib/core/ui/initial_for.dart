import 'package:flutter/widgets.dart';

/// The single uppercase letter an avatar shows for [name], or `?` when there
/// is nothing to show.
///
/// Counts by grapheme ([String.characters]), not by UTF-16 code unit: a name
/// starting with an emoji or a decomposed accent would otherwise come out as
/// half a surrogate pair -- a broken glyph rather than a letter.
String initialFor(String name) =>
    name.trim().characters.firstOrNull?.toUpperCase() ?? '?';
