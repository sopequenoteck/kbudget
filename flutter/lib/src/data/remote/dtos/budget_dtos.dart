// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget_dtos.freezed.dart';
part 'budget_dtos.g.dart';

@freezed
class BudgetRequest with _$BudgetRequest {
  const factory BudgetRequest({
    required String categoryId,
    required double montant,
    required String frequence,
    String? currency,
    int? seuilNotification,
    bool? actif,
  }) = _BudgetRequest;

  factory BudgetRequest.fromJson(Map<String, dynamic> json) =>
      _$BudgetRequestFromJson(json);
}

@freezed
class BudgetResponse with _$BudgetResponse {
  const factory BudgetResponse({
    required String id,
    required double montant,
    required String currency,
    required String frequence,
    required int seuilNotification,
    required bool actif,
    required Map<String, dynamic> category,
    double? spent,
    String? updatedAt,
  }) = _BudgetResponse;

  factory BudgetResponse.fromJson(Map<String, dynamic> json) =>
      _$BudgetResponseFromJson(json);
}

@freezed
class BudgetOverviewResponse with _$BudgetOverviewResponse {
  const factory BudgetOverviewResponse({
    required String month,
    required double totalBudget,
    required double totalSpent,
    required double percentage,
    required String currency,
    required List<BudgetOverviewItemResponse> items,
    @Default([]) List<UnbudgetedItemDto> unbudgetedItems,
    @Default(0) double unbudgetedTotal,
  }) = _BudgetOverviewResponse;

  factory BudgetOverviewResponse.fromJson(Map<String, dynamic> json) =>
      _$BudgetOverviewResponseFromJson(json);
}

@freezed
class BudgetOverviewItemResponse with _$BudgetOverviewItemResponse {
  const factory BudgetOverviewItemResponse({
    required String budgetId,
    required String categoryId,
    required String categoryNom,
    required String categoryIcone,
    required String categoryCouleur,
    required double montantBudget,
    required double montantBudgetNormalise,
    required String currency,
    required double montantDepense,
    required double percentage,
    required String frequence,
  }) = _BudgetOverviewItemResponse;

  factory BudgetOverviewItemResponse.fromJson(Map<String, dynamic> json) =>
      _$BudgetOverviewItemResponseFromJson(json);
}

@freezed
class BudgetHistoryResponse with _$BudgetHistoryResponse {
  const factory BudgetHistoryResponse({
    required String month,
    required double totalBudget,
    required double totalSpent,
    required double percentage,
    required String currency,
    required List<BudgetHistoryItemResponse> items,
    @Default([]) List<UnbudgetedItemDto> unbudgetedItems,
    @Default(0) double unbudgetedTotal,
  }) = _BudgetHistoryResponse;

  factory BudgetHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$BudgetHistoryResponseFromJson(json);
}

@freezed
class BudgetHistoryItemResponse with _$BudgetHistoryItemResponse {
  const factory BudgetHistoryItemResponse({
    required String categoryId,
    required String categoryNom,
    required String categoryIcone,
    required String categoryCouleur,
    required double montantBudget,
    required String currency,
    double? tauxChange,
    required double montantDepense,
    required double percentage,
    DateTime? createdAt,
  }) = _BudgetHistoryItemResponse;

  factory BudgetHistoryItemResponse.fromJson(Map<String, dynamic> json) =>
      _$BudgetHistoryItemResponseFromJson(json);
}

@freezed
class UnbudgetedItemDto with _$UnbudgetedItemDto {
  const factory UnbudgetedItemDto({
    required String categoryId,
    required String categoryNom,
    required String categoryIcone,
    required String categoryCouleur,
    required double montantDepense,
    String? currency,
  }) = _UnbudgetedItemDto;

  factory UnbudgetedItemDto.fromJson(Map<String, dynamic> json) =>
      _$UnbudgetedItemDtoFromJson(json);
}
