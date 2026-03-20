import 'package:drift/drift.dart';
import 'package:k_budget/src/data/local/database.dart' as db;
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/utils/enum_utils.dart';
import 'package:k_budget/src/domain/models/account.dart' as domain;
import 'package:k_budget/src/domain/models/budget.dart' as domain;
import 'package:k_budget/src/domain/models/category.dart' as domain;
import 'package:k_budget/src/domain/models/debt.dart' as domain;
import 'package:k_budget/src/domain/models/subscription.dart' as domain;
import 'package:k_budget/src/domain/models/transaction.dart' as domain;

// --- Transaction ---

domain.Transaction transactionFromDb(db.Transaction row) => domain.Transaction(
      id: row.id,
      montant: row.montant,
      libelle: row.libelle,
      type: TransactionType.values.byNameOrDefault(row.type, TransactionType.depense),
      date: row.date,
      note: row.note,
      transferId: row.transferId,
      categoryId: row.categoryId,
      accountId: row.accountId,
      updatedAt: row.updatedAt,
    );

db.TransactionsCompanion transactionToDb(domain.Transaction t) =>
    db.TransactionsCompanion(
      id: Value(t.id),
      montant: Value(t.montant),
      libelle: Value(t.libelle),
      type: Value(t.type.name),
      date: Value(t.date),
      note: Value(t.note),
      transferId: Value(t.transferId),
      categoryId: Value(t.categoryId),
      accountId: Value(t.accountId),
      updatedAt: Value(t.updatedAt),
    );

// --- Category ---

domain.Category categoryFromDb(db.Category row) => domain.Category(
      id: row.id,
      nom: row.nom,
      icone: row.icone,
      couleur: row.couleur,
      isSystem: row.isSystem,
      updatedAt: row.updatedAt,
    );

db.CategoriesCompanion categoryToDb(domain.Category c) =>
    db.CategoriesCompanion(
      id: Value(c.id),
      nom: Value(c.nom),
      icone: Value(c.icone),
      couleur: Value(c.couleur),
      isSystem: Value(c.isSystem),
      updatedAt: Value(c.updatedAt),
    );

// --- Account ---

domain.Account accountFromDb(db.Account row) => domain.Account(
      id: row.id,
      nom: row.nom,
      type: AccountType.values.byNameOrDefault(row.type, AccountType.courant),
      soldeInitial: row.soldeInitial,
      icone: row.icone,
      couleur: row.couleur,
      isDefault: row.isDefault,
      currency: Currency.values.byNameOrDefault(row.currency, Currency.eur),
      actif: row.actif,
      updatedAt: row.updatedAt,
      bankCode: row.bankCode ?? 'OTHER',
      bankCustomName: row.bankCustomName,
      bankCustomLogo: row.bankCustomLogo,
    );

db.AccountsCompanion accountToDb(domain.Account a) => db.AccountsCompanion(
      id: Value(a.id),
      nom: Value(a.nom),
      type: Value(a.type.name),
      soldeInitial: Value(a.soldeInitial),
      icone: Value(a.icone),
      couleur: Value(a.couleur),
      isDefault: Value(a.isDefault),
      currency: Value(a.currency.name),
      actif: Value(a.actif),
      updatedAt: Value(a.updatedAt),
      bankCode: Value(a.bankCode),
      bankCustomName: Value(a.bankCustomName),
      bankCustomLogo: Value(a.bankCustomLogo),
    );

// --- Subscription ---

domain.Subscription subscriptionFromDb(db.Subscription row) =>
    domain.Subscription(
      id: row.id,
      nom: row.nom,
      montant: row.montant,
      frequence: Frequency.values.byNameOrDefault(row.frequence, Frequency.mensuel),
      dateDebut: row.dateDebut,
      currency: Currency.values.byNameOrDefault(row.currency, Currency.eur),
      actif: row.actif,
      categoryId: row.categoryId,
      accountId: row.accountId,
      updatedAt: row.updatedAt,
    );

db.SubscriptionsCompanion subscriptionToDb(domain.Subscription s) =>
    db.SubscriptionsCompanion(
      id: Value(s.id),
      nom: Value(s.nom),
      montant: Value(s.montant),
      frequence: Value(s.frequence.name),
      dateDebut: Value(s.dateDebut),
      currency: Value(s.currency.name),
      actif: Value(s.actif),
      categoryId: Value(s.categoryId),
      accountId: Value(s.accountId),
      updatedAt: Value(s.updatedAt),
    );

// --- Debt ---

domain.Debt debtFromDb(db.Debt row) => domain.Debt(
      id: row.id,
      personne: row.personne,
      montant: row.montant,
      sens: DebtType.values.byNameOrDefault(row.sens, DebtType.emprunt),
      date: row.date,
      currency: Currency.values.byNameOrDefault(row.currency, Currency.eur),
      rembourse: row.rembourse,
      categoryId: row.categoryId,
      updatedAt: row.updatedAt,
    );

db.DebtsCompanion debtToDb(domain.Debt d) => db.DebtsCompanion(
      id: Value(d.id),
      personne: Value(d.personne),
      montant: Value(d.montant),
      sens: Value(d.sens.name),
      date: Value(d.date),
      currency: Value(d.currency.name),
      rembourse: Value(d.rembourse),
      categoryId: Value(d.categoryId),
      updatedAt: Value(d.updatedAt),
    );

// --- Budget ---

domain.Budget budgetFromDb(db.Budget row) => domain.Budget(
      id: row.id,
      categoryId: row.categoryId,
      montant: row.montant,
      frequence: Frequency.values.byNameOrDefault(row.frequence, Frequency.mensuel),
      currency: Currency.values.byNameOrDefault(row.currency, Currency.eur),
      seuilNotification: row.seuilNotification,
      actif: row.actif,
      updatedAt: row.updatedAt,
    );

db.BudgetsCompanion budgetToDb(domain.Budget b) => db.BudgetsCompanion(
      id: Value(b.id),
      categoryId: Value(b.categoryId),
      montant: Value(b.montant),
      frequence: Value(b.frequence.name),
      currency: Value(b.currency.name),
      seuilNotification: Value(b.seuilNotification),
      actif: Value(b.actif),
      updatedAt: Value(b.updatedAt),
    );
