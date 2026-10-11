// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:k_budget/src/constants/app_spacing.dart';

/// Diameter of a round PIN pad key. Above the 48 px minimum touch target.
const double pinKeySize = 64;

/// Space between two PIN pad keys, horizontally and vertically.
const double pinKeyGap = AppSpacing.space3;

/// Diameter of a PIN progress dot.
const double pinDotSize = 14;

/// Space between two PIN progress dots.
const double pinDotGap = AppSpacing.space4;

/// Width of the outline of an empty PIN dot.
const pinDotOutline = 1.5;

/// Size of the padlock icon on the lock screen.
const double lockIconSize = 48;

/// Size of the icon of a PIN pad key (delete, biometric).
const double pinKeyIconSize = 24;

/// Maximum width of the lock screen content.
const double lockContentMaxWidth = 320;

/// Minimum touch target on a screen with a PIN pad.
const double minTouchTarget = 48;

/// Minimum height reserved for the message, so the pad does not jump when it
/// shows up.
const double pinMessageMinHeight = AppSpacing.space6;
