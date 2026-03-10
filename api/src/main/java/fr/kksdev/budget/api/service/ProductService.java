package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.ProductRequest;
import fr.kksdev.budget.api.dto.request.ProductUpdateRequest;
import fr.kksdev.budget.api.dto.request.RestockRequest;
import fr.kksdev.budget.api.dto.response.AccountSummary;
import fr.kksdev.budget.api.dto.response.CategoryResponse;
import fr.kksdev.budget.api.dto.response.ProductResponse;
import fr.kksdev.budget.api.dto.response.TransactionResponse;
import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.enums.Feature;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.exception.ConflictException;
import fr.kksdev.budget.api.exception.FeatureDisabledException;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.Product;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.UserPreference;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.ProductRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ProductService {

    private final ProductRepository productRepository;
    private final UserRepository userRepository;
    private final PreferenceService preferenceService;
    private final AccountRepository accountRepository;
    private final CategoryService categoryService;
    private final TransactionRepository transactionRepository;

    @Transactional
    public ProductResponse create(ProductRequest request, UUID userId) {
        checkShopEnabled(userId);
        Product product = Product.builder()
                .nom(request.nom())
                .description(request.description())
                .icone(request.icone())
                .imageUrl(request.imageUrl())
                .prixAchat(request.prixAchat())
                .prixVente(request.prixVente())
                .stock(request.stock())
                .actif(true)
                .totalVendu(0)
                .user(userRepository.getReferenceById(userId))
                .build();
        product = productRepository.save(product);
        log.info("Produit créé: {} pour userId {}", product.getId(), userId);
        return toResponse(product);
    }

    public List<ProductResponse> getAllByUser(UUID userId, boolean includeInactive) {
        checkShopEnabled(userId);
        List<Product> products = includeInactive
                ? productRepository.findByUserIdOrderByCreatedAtDesc(userId)
                : productRepository.findByUserIdAndActifTrueOrderByCreatedAtDesc(userId);
        return products.stream()
                .map(this::toResponse)
                .toList();
    }

    public ProductResponse getById(UUID id, UUID userId) {
        checkShopEnabled(userId);
        Product product = findByIdAndUser(id, userId);
        return toResponse(product);
    }

    @Transactional
    public ProductResponse update(UUID id, ProductUpdateRequest request, UUID userId) {
        checkShopEnabled(userId);
        Product product = findByIdAndUser(id, userId);
        product.setNom(request.nom());
        product.setDescription(request.description());
        product.setIcone(request.icone());
        product.setImageUrl(request.imageUrl());
        product.setPrixAchat(request.prixAchat());
        product.setPrixVente(request.prixVente());
        product.setStock(request.stock());
        product.setActif(request.actif());
        product = productRepository.save(product);
        log.info("Produit mis à jour: {}", id);
        return toResponse(product);
    }

    @Transactional
    public void delete(UUID id, UUID userId) {
        checkShopEnabled(userId);
        Product product = findByIdAndUser(id, userId);
        productRepository.delete(product);
        log.info("Produit supprimé: {}", id);
    }

    @Transactional
    public ProductResponse sell(UUID productId, UUID userId, int quantity) {
        checkShopEnabled(userId);
        Product product = findByIdAndUser(productId, userId);

        if (!Boolean.TRUE.equals(product.getActif())) {
            log.error("Vente refusée (inactif): productId={}, userId={}", productId, userId);
            throw new ConflictException("Le produit " + product.getNom() + " est inactif");
        }
        if (product.getStock() < quantity) {
            log.error("Vente refusée (stock insuffisant): productId={}, userId={}, stock={}, quantity={}", productId, userId, product.getStock(), quantity);
            throw new ConflictException("Stock insuffisant pour le produit " + product.getNom());
        }

        int stockBefore = product.getStock();
        product.setStock(stockBefore - quantity);
        product.setTotalVendu(product.getTotalVendu() + quantity);

        Account shopAccount = getOrCreateShopAccount(userId);
        Category shopCategory = categoryService.findOrCreateShopCategory(userId);

        BigDecimal montant = product.getPrixVente().multiply(BigDecimal.valueOf(quantity));
        Transaction transaction = Transaction.builder()
                .montant(montant)
                .libelle("Vente: " + product.getNom() + (quantity > 1 ? " x" + quantity : ""))
                .type(TransactionType.RECETTE)
                .date(LocalDate.now())
                .product(product)
                .account(shopAccount)
                .category(shopCategory)
                .user(userRepository.getReferenceById(userId))
                .build();
        transactionRepository.save(transaction);

        product = productRepository.save(product);
        log.info("Vente produit: id={}, nom={}, userId={}, quantité={}, stock={}->{}, montant={}", productId, product.getNom(), userId, quantity, stockBefore, product.getStock(), montant);
        return toResponse(product);
    }

    @Transactional
    public ProductResponse restock(UUID productId, RestockRequest request, UUID userId) {
        checkShopEnabled(userId);
        Product product = findByIdAndUser(productId, userId);

        if (!Boolean.TRUE.equals(product.getActif())) {
            log.error("Restock refusé (inactif): productId={}, userId={}", productId, userId);
            throw new ConflictException("Le produit " + product.getNom() + " est inactif");
        }

        int stockBefore = product.getStock();
        product.setStock(stockBefore + request.quantity());

        Account shopAccount = getOrCreateShopAccount(userId);
        Category shopCategory = categoryService.findOrCreateShopCategory(userId);

        BigDecimal montant = product.getPrixAchat().multiply(BigDecimal.valueOf(request.quantity()));
        Transaction transaction = Transaction.builder()
                .montant(montant)
                .libelle("Stock: " + product.getNom() + " x" + request.quantity())
                .type(TransactionType.DEPENSE)
                .date(LocalDate.now())
                .product(product)
                .account(shopAccount)
                .category(shopCategory)
                .user(userRepository.getReferenceById(userId))
                .build();
        transactionRepository.save(transaction);

        product = productRepository.save(product);
        log.info("Restock produit: id={}, nom={}, userId={}, quantité={}, stock={}->{}, montant={}", productId, product.getNom(), userId, request.quantity(), stockBefore, product.getStock(), montant);
        return toResponse(product);
    }

    public List<TransactionResponse> getSalesHistory(UUID productId, UUID userId) {
        checkShopEnabled(userId);
        findByIdAndUser(productId, userId);

        return transactionRepository.findByProductIdAndUserIdOrderByDateDesc(productId, userId)
                .stream()
                .map(this::toTransactionResponse)
                .toList();
    }

    @Transactional
    public Account getOrCreateShopAccount(UUID userId) {
        UserPreference prefs = preferenceService.getOrCreatePreference(userId);
        if (prefs.getShopAccountId() != null) {
            return accountRepository.findById(prefs.getShopAccountId())
                    .orElseGet(() -> createShopAccount(userId, prefs));
        }
        return createShopAccount(userId, prefs);
    }

    private Account createShopAccount(UUID userId, UserPreference prefs) {
        Account shopAccount = Account.builder()
                .nom("Boutique")
                .type(AccountType.COURANT)
                .soldeInitial(java.math.BigDecimal.ZERO)
                .icone("🛍️")
                .couleur("#f59e0b")
                .actif(true)
                .user(userRepository.getReferenceById(userId))
                .build();
        shopAccount = accountRepository.save(shopAccount);
        prefs.setShopAccountId(shopAccount.getId());
        log.info("Compte Boutique créé: {} pour userId {}", shopAccount.getId(), userId);
        return shopAccount;
    }

    private void checkShopEnabled(UUID userId) {
        if (!preferenceService.isFeatureEnabled(userId, Feature.SHOP)) {
            throw new FeatureDisabledException("SHOP");
        }
    }

    private Product findByIdAndUser(UUID id, UUID userId) {
        return productRepository.findById(id)
                .filter(p -> p.getUser().getId().equals(userId))
                .orElseThrow(() -> {
                    log.error("Produit non trouvé: id={}, userId={}", id, userId);
                    return new EntityNotFoundException("Produit non trouvé");
                });
    }

    private ProductResponse toResponse(Product product) {
        return new ProductResponse(
                product.getId(),
                product.getNom(),
                product.getDescription(),
                product.getIcone(),
                product.getImageUrl(),
                product.getPrixAchat(),
                product.getPrixVente(),
                product.getStock(),
                product.getTotalVendu(),
                product.getActif(),
                product.getCreatedAt(),
                product.getUpdatedAt()
        );
    }

    private TransactionResponse toTransactionResponse(Transaction transaction) {
        Category cat = transaction.getCategory();
        Account acc = transaction.getAccount();
        return new TransactionResponse(
                transaction.getId(),
                transaction.getMontant(),
                transaction.getLibelle(),
                transaction.getType(),
                transaction.getDate(),
                cat != null ? new CategoryResponse(
                        cat.getId(), cat.getNom(), cat.getIcone(), cat.getCouleur(),
                        Boolean.TRUE.equals(cat.getIsSystem())) : null,
                transaction.getNote(),
                acc != null ? new AccountSummary(
                        acc.getId(), acc.getNom(), acc.getIcone(), acc.getCouleur(),
                        acc.getCurrency().name()) : null,
                transaction.getTransferId(),
                transaction.getProduct() != null ? transaction.getProduct().getId() : null,
                transaction.getProduct() != null ? transaction.getProduct().getNom() : null,
                transaction.getDebt() != null ? transaction.getDebt().getId() : null
        );
    }
}
