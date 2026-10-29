import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Turns a [ValidationIssue] into a sentence in the user's language.
extension ValidationIssueMessage on ValidationIssue {
  /// The translated message for this issue.
  String toMessage(Translations t) => switch (this) {
    MissingInput(input: ValidatedInput.itemName) =>
      t.validation.itemNameMissing,
    MissingInput(input: ValidatedInput.listName) =>
      t.validation.listNameMissing,
    MissingInput(input: ValidatedInput.shopName) =>
      t.validation.shopNameMissing,
    MissingInput(input: ValidatedInput.displayName) =>
      t.validation.displayNameMissing,
    MissingInput(input: ValidatedInput.avatarPhoto) =>
      t.validation.photoMissing,
    MissingInput(input: ValidatedInput.password) =>
      t.validation.passwordMissing,
    TooLongInput(:final max) => t.validation.tooLong(max: max),
    TooShortInput(:final min) => t.validation.tooShort(min: min),
    TooFewInput(input: ValidatedInput.quantity, :final min) =>
      t.validation.quantityTooFew(min: min),
    TooLargeInput(input: ValidatedInput.avatarPhoto, :final maxBytes) =>
      t.validation.photoTooLarge(megabytes: maxBytes ~/ (1024 * 1024)),
    InvalidFormatInput(input: ValidatedInput.joinCode) =>
      t.validation.joinCodeInvalid,
    InvalidFormatInput(input: ValidatedInput.color) =>
      t.validation.colorInvalid,
    // The password rule's only format check.
    InvalidFormatInput(input: ValidatedInput.password) =>
      t.validation.passwordSpacesAtEnds,
    InvalidFormatInput(input: ValidatedInput.email) =>
      t.validation.emailInvalid,
    InvalidFormatInput(input: ValidatedInput.verificationCode) =>
      t.validation.codeInvalid,
    NotFoundInput(input: ValidatedInput.joinCode) =>
      t.validation.joinCodeNotFound,
    AlreadyInUseInput(input: ValidatedInput.email) => t.validation.emailInUse,
    // Combinations no rule produces today.
    _ => t.errors.validation,
  };
}
