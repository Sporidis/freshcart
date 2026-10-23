import 'package:freezed_annotation/freezed_annotation.dart';

part 'validation_issue.freezed.dart';

/// Which input broke a rule.
enum ValidatedInput {
  /// An item's name.
  itemName,

  /// A list's name.
  listName,

  /// A shop's name (its tab).
  shopName,

  /// The name others see next to a user's changes.
  displayName,

  /// How many of an item.
  quantity,

  /// The code someone types to join a list.
  joinCode,

  /// A user's avatar photo.
  avatarPhoto,

  /// A colour typed as hex (`#4CAF50`).
  color,

  /// An email address, when linking one to an account.
  email,
}

/// What's wrong with a [ValidatedInput], as data, not as a sentence: the
/// app turns it into text in the user's language.
@freezed
sealed class ValidationIssue with _$ValidationIssue {
  /// Required, but empty: a blank name, or a photo with no bytes.
  const factory ValidationIssue.missing(ValidatedInput input) = MissingInput;

  /// Longer than [max] characters.
  const factory ValidationIssue.tooLong(
    ValidatedInput input, {
    required int max,
  }) = TooLongInput;

  /// Shorter than [min] characters.
  const factory ValidationIssue.tooShort(
    ValidatedInput input, {
    required int min,
  }) = TooShortInput;

  /// Fewer than [min] (a quantity).
  const factory ValidationIssue.tooFew(
    ValidatedInput input, {
    required int min,
  }) = TooFewInput;

  /// Bigger than [maxBytes] (a file).
  const factory ValidationIssue.tooLarge(
    ValidatedInput input, {
    required int maxBytes,
  }) = TooLargeInput;

  /// Not in the expected shape (a join code's characters, a hex colour).
  const factory ValidationIssue.invalidFormat(ValidatedInput input) =
      InvalidFormatInput;

  /// Well-formed, but it matches nothing (a join code for no list). A
  /// validation issue, not [Failure.notFound], so it shows at the field.
  const factory ValidationIssue.notFound(ValidatedInput input) = NotFoundInput;

  /// Already taken by someone else (an email linked to another account).
  const factory ValidationIssue.alreadyInUse(ValidatedInput input) =
      AlreadyInUseInput;
}
