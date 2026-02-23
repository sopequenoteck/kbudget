enum TextScale {
  small,
  medium,
  large;

  double get scaleFactor => switch (this) {
        TextScale.small => 0.85,
        TextScale.medium => 1.0,
        TextScale.large => 1.3,
      };

  String get label => switch (this) {
        TextScale.small => 'Petit',
        TextScale.medium => 'Normal',
        TextScale.large => 'Grand',
      };
}
