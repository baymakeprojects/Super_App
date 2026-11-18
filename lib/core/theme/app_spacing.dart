/// Spasi dari variabel Figma Spacing/4 … Spacing/32 (kelipatan 4).
abstract final class AppSpace {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
}

/// Sudut dari variabel Figma Radius/….
abstract final class AppRadius {
  /// Radius/Input.
  static const double input = 10;

  /// Radius/Button.
  static const double button = 12;

  /// Radius/Item — dipakai komponen di Components [06] Pola layar.
  static const double item = 16;

  /// Radius/Card.
  static const double card = 20;

  /// Radius/Full — bentuk pil (chip, avatar).
  static const double full = 999;
}
