import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';

final textScaleNotifierProvider =
    NotifierProvider<TextScaleNotifier, TextScale>(TextScaleNotifier.new);

class TextScaleNotifier extends Notifier<TextScale> {
  @override
  TextScale build() {
    _loadTextScale();
    return TextScale.medium;
  }

  Future<void> _loadTextScale() async {
    final repo = ref.read(appConfigRepositoryProvider);
    final textScale = await repo.getTextScale();
    state = textScale;
  }

  Future<void> setTextScale(TextScale textScale) async {
    state = textScale;
    final repo = ref.read(appConfigRepositoryProvider);
    await repo.setTextScale(textScale);
  }
}
