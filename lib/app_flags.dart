/// App-wide feature flags.
class AppFlags {
  AppFlags._();

  /// TEMPORARY (testing): when true, the AI Photo Coach is available on **every
  /// tier**, not just Magnet — so you can test photo uploads without upgrading.
  ///
  /// Set back to `false` to restore the premium gate before launch.
  static const bool unlockPhotoCoachForTesting = true;
}
