// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

/// Interface CRUD de base pour les repositories.
abstract class CrudRepository<T> {
  Future<List<T>> getAll();
  Future<T> create(T item);
  Future<T> update(T item);
  Future<void> delete(String id);
}
