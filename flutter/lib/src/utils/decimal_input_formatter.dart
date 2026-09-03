// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/services.dart';

class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter({this.decimalPlaces = 2});

  final int decimalPlaces;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) return newValue;

    final pattern = RegExp(r'^\d*[.,]?\d{0,' + decimalPlaces.toString() + r'}$');

    if (!pattern.hasMatch(text)) return oldValue;

    final normalized = text.replaceAll(',', '.');

    return newValue.copyWith(text: normalized);
  }
}
