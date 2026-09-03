// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:k_budget/src/domain/models/subscription.dart';
import 'package:k_budget/src/domain/models/subscription_payment.dart';
import 'package:k_budget/src/domain/models/subscription_total_paid.dart';

abstract class SubscriptionRepository {
  Future<List<Subscription>> getAll();
  Stream<List<Subscription>> watchAll();
  Future<Subscription> getById(String id);
  Future<Subscription> create(Subscription subscription);
  Future<Subscription> update(Subscription subscription);
  Future<void> delete(String id);
  Future<SubscriptionPayment> pay(String id);
  Future<List<SubscriptionPayment>> getPayments(String id);
  Future<SubscriptionTotalPaid> getTotalPaid(String id);
}
