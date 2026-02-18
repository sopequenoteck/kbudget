import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:k_budget/src/data/local/daos/account_dao.dart';
import 'package:k_budget/src/data/local/daos/category_dao.dart';
import 'package:k_budget/src/data/local/daos/debt_dao.dart';
import 'package:k_budget/src/data/local/daos/subscription_dao.dart';
import 'package:k_budget/src/data/local/daos/transaction_dao.dart';

part 'database.g.dart';

// --- Table definitions ---

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get nom => text()();
  TextColumn get icone => text()();
  TextColumn get couleur => text()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get nom => text()();
  TextColumn get type => text()();
  RealColumn get soldeInitial => real()();
  TextColumn get icone => text()();
  TextColumn get couleur => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  TextColumn get currency => text().withDefault(const Constant('eur'))();
  BoolColumn get actif => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text()();
  RealColumn get montant => real()();
  TextColumn get libelle => text()();
  TextColumn get type => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get transferId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get accountId => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Subscriptions extends Table {
  TextColumn get id => text()();
  TextColumn get nom => text()();
  RealColumn get montant => real()();
  TextColumn get frequence => text()();
  DateTimeColumn get dateDebut => dateTime()();
  TextColumn get currency => text().withDefault(const Constant('eur'))();
  BoolColumn get actif => boolean().withDefault(const Constant(true))();
  TextColumn get categoryId => text().nullable()();
  TextColumn get accountId => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Debts extends Table {
  TextColumn get id => text()();
  TextColumn get personne => text()();
  RealColumn get montant => real()();
  TextColumn get sens => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get currency => text().withDefault(const Constant('eur'))();
  BoolColumn get rembourse => boolean().withDefault(const Constant(false))();
  TextColumn get categoryId => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Database ---

@DriftDatabase(
  tables: [Categories, Accounts, Transactions, Subscriptions, Debts],
  daos: [CategoryDao, AccountDao, TransactionDao, SubscriptionDao, DebtDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'k_budget'));

  @override
  int get schemaVersion => 1;
}
