/// Whether the user has been through the welcome pages.
///
/// Lived in `startup_gate.dart` until Phase 7 folded that screen into the
/// splash; it sits on its own now so the splash and the welcome screen can
/// share it without either importing the other.
const onboardingCompletedPrefsKey = 'onboarding_completed_v1';
