// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/subscription.dart';

part 'subscription_list_state.freezed.dart';

@freezed
class SubscriptionListState with _$SubscriptionListState {
  const factory SubscriptionListState({
    @Default([]) List<Subscription> items,
    @Default(false) bool isLoading,
    String? error,
    @Default(SubscriptionStatusFilter.all)
    SubscriptionStatusFilter activeFilter,
    @Default({}) Map<Currency, double> monthlyTotals,
    @Default(0) int currentPage,
    @Default(true) bool hasMore,
    @Default({}) Set<String> mutatingIds,
  }) = _SubscriptionListState;
}
