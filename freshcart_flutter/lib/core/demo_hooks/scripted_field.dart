/// A text field the web demo's director can type into (decisions.md #109).
///
/// Only these fields, because they keep their text in a private
/// `TextEditingController` that nothing outside the widget can reach.
enum ScriptedField {
  /// Onboarding step 1: "What should we call you?".
  onboardingName,

  /// Onboarding step 2: the list's name.
  onboardingListName,

  /// Join flow: the name step.
  joinName,

  /// Join flow: the five code boxes.
  joinCode,
}
