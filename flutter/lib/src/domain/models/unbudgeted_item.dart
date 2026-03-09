import 'package:freezed_annotation/freezed_annotation.dart';

part 'unbudgeted_item.freezed.dart';
part 'unbudgeted_item.g.dart';

@freezed
class UnbudgetedItem with _$UnbudgetedItem {
  const factory UnbudgetedItem({
    required String categoryId,
    required String categoryNom,
    required String categoryIcone,
    required String categoryCouleur,
    required double montantDepense,
  }) = _UnbudgetedItem;

  factory UnbudgetedItem.fromJson(Map<String, dynamic> json) =>
      _$UnbudgetedItemFromJson(json);
}
