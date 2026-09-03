// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

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
