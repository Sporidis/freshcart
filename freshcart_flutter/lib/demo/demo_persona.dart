import 'package:freshcart_domain/freshcart_domain.dart';

/// Who is holding one of the demo phones.
///
/// [name] isn't stored up front: the user starts with an empty name, and
/// onboarding (or the director, in D4) types it. There's no fixed colour
/// either: like a real new user, the avatar gets the automatic colour for
/// its id, the same one onboarding shows.
class DemoPersona {
  const DemoPersona._(this._id, this.name);

  /// Phone A: creates the list.
  static const a = DemoPersona._('demo-nikolaos', 'Nikolaos');

  /// Phone B: joins it with A's code.
  static const b = DemoPersona._('demo-anna', 'Anna');

  final String _id;

  /// The name onboarding types for this persona.
  final String name;

  UserId get id => UserId(_id);
}
