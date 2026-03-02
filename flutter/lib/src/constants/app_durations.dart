import 'package:flutter/widgets.dart';

class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 400);

  static const Cubic easeDefault = Cubic(0.4, 0, 0.2, 1);
  static const Cubic easeIn = Cubic(0.4, 0, 1, 1);
  static const Cubic easeOut = Cubic(0, 0, 0.2, 1);

  /// Alias for backward compatibility.
  static const Cubic easeInOut = easeDefault;

  /// Returns [Duration.zero] if the user has enabled reduced-motion in OS settings,
  /// otherwise returns the given [duration].
  static Duration resolve(Duration duration, BuildContext context) {
    return MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : duration;
  }
}
