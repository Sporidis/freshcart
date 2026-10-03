import 'package:flutter/widgets.dart';

/// The first letter of [name], in uppercase, for an avatar. `?` if empty.
///
/// Uses [String.characters] instead of `name[0]`. `name[0]` would break
/// names starting with an emoji or some accented letters, because those are
/// stored as more than one code unit.
String initialFor(String name) =>
    name.trim().characters.firstOrNull?.toUpperCase() ?? '?';
