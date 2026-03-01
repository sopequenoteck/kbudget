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
