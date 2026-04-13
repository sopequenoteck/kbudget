package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.AccountRequest;
import fr.kksdev.budget.api.dto.request.TransferRequest;
import fr.kksdev.budget.api.dto.response.AccountResponse;
import fr.kksdev.budget.api.dto.response.CurrencyBalance;
import fr.kksdev.budget.api.dto.response.TotalBalanceResponse;
import fr.kksdev.budget.api.dto.response.TransferResponse;
import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.enums.DebtType;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.Debt;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.DebtRepository;
import fr.kksdev.budget.api.repository.SubscriptionRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AccountService {

    private final AccountRepository accountRepository;
    private final TransactionRepository transactionRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final UserRepository userRepository;
    private final CategoryService categoryService;
    private final PreferenceService preferenceService;
    private final DebtRepository debtRepository;
    private final BankService bankService;

    public List<AccountResponse> getAccounts(UUID userId, boolean includeInactive) {
        List<Account> accounts = includeInactive
                ? accountRepository.findByUserId(userId)
                : accountRepository.findByUserIdAndActifTrue(userId);
        return accounts.stream()
                .map(this::toResponse)
                .toList();
    }

    public AccountResponse getAccountById(UUID id, UUID userId) {
        Account account = findByIdAndUser(id, userId);
        return toResponse(account);
    }

    @Transactional
    public AccountResponse createAccount(AccountRequest request, UUID userId) {
        if (accountRepository.existsByNomIgnoreCaseAndUserIdAndActifTrue(request.nom(), userId)) {
            throw new IllegalArgumentException("Un compte avec ce nom existe déjà");
        }

        AccountType type = request.type();
        String icone = request.icone() != null ? request.icone() : type.getDefaultIcone();
        String couleur = request.couleur() != null ? request.couleur() : type.getDefaultCouleur();
        BigDecimal soldeInitial = request.soldeInitial() != null ? request.soldeInitial() : BigDecimal.ZERO;

        User user = userRepository.getReferenceById(userId);
        Currency currency = request.currency() != null ? request.currency()
                : preferenceService.getOrCreatePreference(userId).getCurrencies().get(0);

        String bankCode = request.bankCode() != null ? request.bankCode().toUpperCase() : "OTHER";
        if (BankRegistry.findByCode(bankCode).isEmpty()) {
            throw new IllegalArgumentException("Invalid bank code: " + request.bankCode());
        }

        Account account = Account.builder()
                .nom(request.nom())
                .type(type)
                .soldeInitial(soldeInitial)
                .icone(icone)
                .couleur(couleur)
                .currency(currency)
                .user(user)
                .bankCode(bankCode)
                .bankCustomName(request.bankCustomName())
                .bankCustomLogo(request.bankCustomLogo())
                .build();

        account = accountRepository.save(account);
        if (!"OTHER".equals(bankCode)) {
            log.info("Compte créé: {} pour userId {}, bankCode={}", account.getId(), userId, bankCode);
        } else {
            log.info("Compte créé: {} pour userId {}", account.getId(), userId);
        }
        return toResponse(account);
    }

    @Transactional
    public AccountResponse updateAccount(UUID id, AccountRequest request, UUID userId) {
        Account account = findByIdAndUser(id, userId);

        if (accountRepository.existsByNomIgnoreCaseAndUserIdAndActifTrueAndIdNot(request.nom(), userId, id)) {
            throw new IllegalArgumentException("Un compte avec ce nom existe déjà");
        }

        if (request.currency() != null && request.currency() != account.getCurrency()) {
            throw new IllegalArgumentException("La devise d'un compte ne peut pas être modifiée");
        }

        // Gérer actif si présent dans la requête
        if (request.actif() != null && !request.actif() && Boolean.TRUE.equals(account.getIsDefault())) {
            throw new IllegalArgumentException("Impossible de désactiver le compte par défaut");
        }

        if (request.bankCode() != null) {
            String newBankCode = request.bankCode().toUpperCase();
            if (BankRegistry.findByCode(newBankCode).isEmpty()) {
                throw new IllegalArgumentException("Invalid bank code: " + request.bankCode());
            }
            String oldBankCode = account.getBankCode();
            if (!newBankCode.equals(oldBankCode)) {
                log.info("Banque modifiée sur compte {}: {} -> {}", account.getId(), oldBankCode, newBankCode);
            }
            account.setBankCode(newBankCode);
        }

        account.setNom(request.nom());
        account.setType(request.type());
        // soldeInitial est ignoré en PUT (figé après création)
        account.setIcone(request.icone() != null ? request.icone() : request.type().getDefaultIcone());
        account.setCouleur(request.couleur() != null ? request.couleur() : request.type().getDefaultCouleur());
        account.setBankCustomName(request.bankCustomName());
        account.setBankCustomLogo(request.bankCustomLogo());
        if (request.actif() != null) {
            account.setActif(request.actif());
        }

        account = accountRepository.save(account);
        log.info("Compte mis à jour: {}", account.getId());
        return toResponse(account);
    }

    @Transactional
    public void deleteAccount(UUID id, UUID userId) {
        Account account = findByIdAndUser(id, userId);

        if (Boolean.TRUE.equals(account.getIsDefault())) {
            throw new IllegalArgumentException("Impossible de supprimer le compte par défaut");
        }

        if (transactionRepository.existsByAccountId(id)) {
            throw new IllegalArgumentException("Impossible de supprimer un compte avec des transactions rattachées");
        }

        if (subscriptionRepository.existsByAccountId(id)) {
            throw new IllegalArgumentException("Impossible de supprimer un compte avec des abonnements rattachés");
        }

        accountRepository.delete(account);
        log.info("Compte supprimé: {}", id);
    }

    @Transactional
    public AccountResponse setDefault(UUID id, UUID userId) {
        Account account = findByIdAndUser(id, userId);

        if (!Boolean.TRUE.equals(account.getActif())) {
            throw new IllegalArgumentException("Impossible de définir un compte inactif comme compte par défaut");
        }

        // Retirer le défaut de l'ancien compte
        accountRepository.findByUserIdAndIsDefaultTrue(userId)
                .ifPresent(current -> {
                    current.setIsDefault(false);
                    accountRepository.save(current);
                });

        // Définir le nouveau défaut
        account.setIsDefault(true);
        account = accountRepository.save(account);
        log.info("Compte par défaut défini: {} pour userId {}", id, userId);
        return toResponse(account);
    }

    @Transactional
    public TransferResponse transfer(TransferRequest request, UUID userId) {
        if (request.fromAccountId().equals(request.toAccountId())) {
            throw new IllegalArgumentException("Les comptes source et destination doivent être différents");
        }

        Account fromAccount = findByIdAndUser(request.fromAccountId(), userId);
        Account toAccount = findByIdAndUser(request.toAccountId(), userId);

        if (!Boolean.TRUE.equals(fromAccount.getActif())) {
            throw new IllegalArgumentException("Le compte source est inactif");
        }
        if (!Boolean.TRUE.equals(toAccount.getActif())) {
            throw new IllegalArgumentException("Le compte destination est inactif");
        }

        if (fromAccount.getCurrency() != toAccount.getCurrency()) {
            throw new IllegalArgumentException("Le virement entre comptes de devises différentes n'est pas autorisé");
        }

        Category virementCategory = categoryService.findSystemCategoryByNom("Virement", userId);
        if (virementCategory == null) {
            throw new IllegalStateException("Catégorie système 'Virement' introuvable");
        }
        UUID transferId = UUID.randomUUID();
        LocalDate today = LocalDate.now();
        User userRef = userRepository.getReferenceById(userId);

        Transaction debit = Transaction.builder()
                .montant(request.montant())
                .libelle("Virement vers " + toAccount.getNom())
                .type(TransactionType.DEPENSE)
                .date(today)
                .category(virementCategory)
                .note(request.note())
                .account(fromAccount)
                .transferId(transferId)
                .user(userRef)
                .build();

        Transaction credit = Transaction.builder()
                .montant(request.montant())
                .libelle("Virement depuis " + fromAccount.getNom())
                .type(TransactionType.RECETTE)
                .date(today)
                .category(virementCategory)
                .note(request.note())
                .account(toAccount)
                .transferId(transferId)
                .user(userRef)
                .build();

        debit = transactionRepository.save(debit);
        credit = transactionRepository.save(credit);
        log.info("Virement effectué: {} -> {}, montant={}, transferId={}", fromAccount.getId(), toAccount.getId(), request.montant(), transferId);

        return new TransferResponse(
                transferId,
                new TransferResponse.TransactionResponseRef(
                        debit.getId(), debit.getMontant(), debit.getLibelle(),
                        debit.getType(), debit.getDate(), fromAccount.getId(), fromAccount.getNom()),
                new TransferResponse.TransactionResponseRef(
                        credit.getId(), credit.getMontant(), credit.getLibelle(),
                        credit.getType(), credit.getDate(), toAccount.getId(), toAccount.getNom())
        );
    }

    @Transactional
    public AccountResponse adjustBalance(UUID accountId, BigDecimal newBalance, UUID userId) {
        Account account = findByIdAndUser(accountId, userId);

        if (!Boolean.TRUE.equals(account.getActif())) {
            throw new IllegalArgumentException("Impossible d'ajuster le solde d'un compte inactif");
        }

        BigDecimal balance = transactionRepository.calculateBalanceByAccountId(accountId);
        BigDecimal currentBalance = account.getSoldeInitial().add(balance);
        BigDecimal diff = newBalance.subtract(currentBalance);

        if (diff.compareTo(BigDecimal.ZERO) == 0) {
            log.info("Ajustement ignoré (solde identique): accountId={}, userId={}", accountId, userId);
            return toResponse(account);
        }

        Category adjustmentCategory = categoryService.findOrCreateAdjustmentCategory(userId);

        Transaction adjustment = Transaction.builder()
                .montant(diff)
                .libelle("Ajustement de solde")
                .type(TransactionType.AJUSTEMENT)
                .date(LocalDate.now())
                .category(adjustmentCategory)
                .account(account)
                .user(userRepository.getReferenceById(userId))
                .build();

        transactionRepository.save(adjustment);
        log.info("Solde ajusté: accountId={}, diff={}, userId={}", accountId, diff, userId);
        return toResponse(account);
    }

    public TotalBalanceResponse getTotalBalance(UUID userId) {
        // Somme des soldes des comptes actifs par devise
        Map<Currency, BigDecimal> balances = new LinkedHashMap<>();
        List<Account> activeAccounts = accountRepository.findByUserIdAndActifTrue(userId);
        for (Account account : activeAccounts) {
            BigDecimal txBalance = transactionRepository.calculateBalanceByAccountId(account.getId());
            BigDecimal total = account.getSoldeInitial().add(txBalance);
            balances.merge(account.getCurrency(), total, BigDecimal::add);
        }

        // Ajuster par les dettes non remboursées
        List<Debt> unpaidDebts = debtRepository.findByUserIdAndRembourseFalse(userId);

        // Batch: charger tous les montants payés en une requête
        List<UUID> eligibleDebtIds = unpaidDebts.stream()
                .filter(d -> d.getAccount() != null || Boolean.TRUE.equals(d.getIncludeInBalance()))
                .map(Debt::getId)
                .toList();
        Map<UUID, BigDecimal> paidMap = new HashMap<>();
        if (!eligibleDebtIds.isEmpty()) {
            for (Object[] row : transactionRepository.sumByDebtIds(eligibleDebtIds)) {
                paidMap.put((UUID) row[0], (BigDecimal) row[1]);
            }
        }

        for (Debt debt : unpaidDebts) {
            boolean eligible;
            if (debt.getAccount() != null) {
                eligible = true; // Dettes avec compte: toujours incluses
            } else {
                eligible = Boolean.TRUE.equals(debt.getIncludeInBalance());
            }

            if (eligible) {
                BigDecimal paid = paidMap.getOrDefault(debt.getId(), BigDecimal.ZERO);
                BigDecimal remaining = debt.getMontant().subtract(paid);

                Currency currency = debt.getCurrency();
                if (debt.getSens() == DebtType.EMPRUNT) {
                    balances.merge(currency, remaining.negate(), BigDecimal::add);
                } else {
                    balances.merge(currency, remaining, BigDecimal::add);
                }
            }
        }

        // Trier: devise principale en premier
        Currency primaryCurrency = preferenceService.getOrCreatePreference(userId).getCurrencies().get(0);
        List<CurrencyBalance> result = balances.entrySet().stream()
                .sorted((a, b) -> {
                    if (a.getKey() == primaryCurrency && b.getKey() != primaryCurrency) return -1;
                    if (a.getKey() != primaryCurrency && b.getKey() == primaryCurrency) return 1;
                    return a.getKey().compareTo(b.getKey());
                })
                .map(e -> new CurrencyBalance(e.getKey(), e.getValue()))
                .toList();

        return new TotalBalanceResponse(result);
    }

    @Transactional
    public void createDefaultAccount(User user, Currency currency) {
        try {
            Account defaultAccount = Account.builder()
                    .nom("Compte Principal")
                    .type(AccountType.COURANT)
                    .soldeInitial(BigDecimal.ZERO)
                    .icone(AccountType.COURANT.getDefaultIcone())
                    .couleur(AccountType.COURANT.getDefaultCouleur())
                    .isDefault(true)
                    .currency(currency)
                    .user(user)
                    .build();
            accountRepository.save(defaultAccount);
            log.info("Compte par défaut créé pour userId {}", user.getId());
        } catch (Exception e) {
            log.error("Échec de la création du compte par défaut pour userId {}: {}", user.getId(), e.getMessage());
            throw e;
        }
    }

    private Account findByIdAndUser(UUID id, UUID userId) {
        return accountRepository.findById(id)
                .filter(a -> a.getUser().getId().equals(userId))
                .orElseThrow(() -> {
                    log.error("Compte non trouvé: id={}, userId={}", id, userId);
                    return new EntityNotFoundException("Compte non trouvé");
                });
    }

    private AccountResponse toResponse(Account account) {
        BigDecimal balance = transactionRepository.calculateBalanceByAccountId(account.getId());
        BigDecimal solde = account.getSoldeInitial().add(balance);
        BankService.BankResolvedInfo bankInfo = bankService.resolveBank(account);
        return new AccountResponse(
                account.getId(),
                account.getNom(),
                account.getType(),
                account.getSoldeInitial(),
                solde,
                account.getIcone(),
                account.getCouleur(),
                Boolean.TRUE.equals(account.getIsDefault()),
                Boolean.TRUE.equals(account.getActif()),
                account.getCurrency().name(),
                bankInfo.bankCode(),
                bankInfo.bankName(),
                bankInfo.bankCountry(),
                bankInfo.bankBrandColor(),
                bankInfo.bankLogoUrl(),
                bankInfo.bankCustomName(),
                bankInfo.bankCustomLogo()
        );
    }
}
