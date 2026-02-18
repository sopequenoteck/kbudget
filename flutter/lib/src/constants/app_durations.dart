import 'package:flutter/animation.dart';

class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 400);

  static const Cubic easeIn = Cubic(0.4, 0, 1, 1);
  static const Cubic easeOut = Cubic(0, 0, 0.2, 1);
  static const Cubic easeInOut = Cubic(0.4, 0, 0.2, 1);
}
