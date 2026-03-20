import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:k_budget/src/data/local/daos/account_dao.dart';
import 'package:k_budget/src/data/local/daos/budget_dao.dart';
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
  TextColumn get bankCode => text().nullable()();
  TextColumn get bankCustomName => text().nullable()();
  TextColumn get bankCustomLogo => text().nullable()();

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

class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  RealColumn get montant => real()();
  TextColumn get frequence => text()();
  TextColumn get currency => text().withDefault(const Constant('eur'))();
  IntColumn get seuilNotification => integer().withDefault(const Constant(80))();
  BoolColumn get actif => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class BudgetSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  RealColumn get montantBudget => real()();
  TextColumn get currency => text()();
  RealColumn get tauxChange => real().nullable()();
  RealColumn get montantDepense => real()();
  TextColumn get mois => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Database ---

@DriftDatabase(
  tables: [Categories, Accounts, Transactions, Subscriptions, Debts, Budgets, BudgetSnapshots],
  daos: [CategoryDao, AccountDao, TransactionDao, SubscriptionDao, DebtDao, BudgetDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(
          executor ??
              driftDatabase(
                name: 'k_budget',
                web: DriftWebOptions(
                  sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                  driftWorker: Uri.parse('drift_worker.dart.js'),
                ),
              ),
        );

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 3) {
            await m.addColumn(accounts, accounts.bankCode);
            await m.addColumn(accounts, accounts.bankCustomName);
            await m.addColumn(accounts, accounts.bankCustomLogo);
          }
        },
      );
}
