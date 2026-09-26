package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.CategoryRequest;
import fr.kksdev.budget.api.dto.response.CategoryResponse;
import fr.kksdev.budget.api.enums.SystemCategoryKey;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CategoryServiceTest {

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @InjectMocks
    private CategoryService categoryService;

    private final UUID userId = UUID.randomUUID();
    private final UUID categoryId = UUID.randomUUID();

    private User buildUser() {
        return User.builder().id(userId).email("test@mail.com").build();
    }

    private Category buildCategory(User user) {
        return Category.builder()
                .id(categoryId)
                .nom("Alimentation")
                .icone("🍔")
                .couleur("#FF5733")
                .user(user)
                .build();
    }

    private Category buildSystemCategory(User user, String nom, String icone, SystemCategoryKey key) {
        return Category.builder()
                .id(UUID.randomUUID())
                .nom(nom)
                .icone(icone)
                .couleur("#6366f1")
                .isSystem(true)
                .systemKey(key)
                .user(user)
                .build();
    }

    @Test
    void should_create_category_when_valid_request() {
        var user = buildUser();
        var request = new CategoryRequest("Alimentation", "🍔", "#FF5733");
        var saved = buildCategory(user);

        when(categoryRepository.existsByNomIgnoreCaseAndUserId("Alimentation", userId)).thenReturn(false);
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(categoryRepository.save(any(Category.class))).thenReturn(saved);

        CategoryResponse response = categoryService.create(request, userId);

        assertThat(response.id()).isEqualTo(categoryId);
        assertThat(response.nom()).isEqualTo("Alimentation");
        assertThat(response.icone()).isEqualTo("🍔");
        assertThat(response.couleur()).isEqualTo("#FF5733");
        assertThat(response.isSystem()).isFalse();
        assertThat(response.systemKey()).isNull();
        verify(categoryRepository).save(any(Category.class));
    }

    @Test
    void should_throw_when_create_with_duplicate_name() {
        var request = new CategoryRequest("Alimentation", "🍔", "#FF5733");

        when(categoryRepository.existsByNomIgnoreCaseAndUserId("Alimentation", userId)).thenReturn(true);

        assertThatThrownBy(() -> categoryService.create(request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("A category with this name already exists");
    }

    @Test
    void should_rejectDuplicate_when_caseInsensitiveName() {
        var request = new CategoryRequest("alimentation", "🍔", "#FF5733");

        when(categoryRepository.existsByNomIgnoreCaseAndUserId("alimentation", userId)).thenReturn(true);

        assertThatThrownBy(() -> categoryService.create(request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("A category with this name already exists");
    }

    @Test
    void should_return_all_categories_when_user_has_categories() {
        var user = buildUser();
        when(categoryRepository.findByUserIdOrderByNomAsc(userId))
                .thenReturn(List.of(buildCategory(user)));

        List<CategoryResponse> result = categoryService.getAllByUser(userId);

        assertThat(result).hasSize(1);
        assertThat(result.getFirst().nom()).isEqualTo("Alimentation");
    }

    @Test
    void should_return_empty_list_when_user_has_no_categories() {
        when(categoryRepository.findByUserIdOrderByNomAsc(userId)).thenReturn(List.of());

        List<CategoryResponse> result = categoryService.getAllByUser(userId);

        assertThat(result).isEmpty();
    }

    @Test
    void should_return_category_when_found_and_owned() {
        var user = buildUser();
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(buildCategory(user)));

        CategoryResponse response = categoryService.getById(categoryId, userId);

        assertThat(response.id()).isEqualTo(categoryId);
        assertThat(response.nom()).isEqualTo("Alimentation");
        assertThat(response.systemKey()).isNull();
    }

    @Test
    void should_returnSystemKey_when_categoryIsSystem() {
        var user = buildUser();
        var systemCat = buildSystemCategory(user, "Abonnement", "🔄", SystemCategoryKey.SUBSCRIPTION);
        var catId = systemCat.getId();
        when(categoryRepository.findById(catId)).thenReturn(Optional.of(systemCat));

        CategoryResponse response = categoryService.getById(catId, userId);

        assertThat(response.isSystem()).isTrue();
        assertThat(response.systemKey()).isEqualTo("SUBSCRIPTION");
    }

    @Test
    void should_throw_when_category_not_found() {
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> categoryService.getById(categoryId, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Category not found");
    }

    @Test
    void should_throw_when_category_belongs_to_other_user() {
        var otherUser = User.builder().id(UUID.randomUUID()).email("other@mail.com").build();
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(buildCategory(otherUser)));

        assertThatThrownBy(() -> categoryService.getById(categoryId, userId))
                .isInstanceOf(EntityNotFoundException.class);
    }

    @Test
    void should_update_category_when_valid() {
        var user = buildUser();
        var existing = buildCategory(user);
        var request = new CategoryRequest("Transport", "🚗", "#3498DB");

        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(existing));
        when(categoryRepository.existsByNomIgnoreCaseAndUserIdAndIdNot("Transport", userId, categoryId)).thenReturn(false);
        when(categoryRepository.save(any(Category.class))).thenReturn(existing);

        CategoryResponse response = categoryService.update(categoryId, request, userId);

        assertThat(response).isNotNull();
        verify(categoryRepository).save(existing);
    }

    @Test
    void should_throw_when_update_with_duplicate_name() {
        var user = buildUser();
        var existing = buildCategory(user);
        var request = new CategoryRequest("Transport", "🚗", "#3498DB");

        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(existing));
        when(categoryRepository.existsByNomIgnoreCaseAndUserIdAndIdNot("Transport", userId, categoryId)).thenReturn(true);

        assertThatThrownBy(() -> categoryService.update(categoryId, request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("A category with this name already exists");
    }

    @Test
    void should_throw_when_updateSystemCategory() {
        var user = buildUser();
        var systemCat = buildSystemCategory(user, "Abonnement", "🔄", SystemCategoryKey.SUBSCRIPTION);
        var catId = systemCat.getId();
        var request = new CategoryRequest("Renamed", "🔄", "#6366f1");

        when(categoryRepository.findById(catId)).thenReturn(Optional.of(systemCat));

        assertThatThrownBy(() -> categoryService.update(catId, request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("System categories cannot be updated");
        verify(categoryRepository, never()).save(any());
    }

    @Test
    void should_delete_category_when_found_and_owned() {
        var user = buildUser();
        var category = buildCategory(user);

        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(category));

        categoryService.delete(categoryId, userId);

        verify(categoryRepository).delete(category);
    }

    @Test
    void should_throw_when_deleteSystemCategory() {
        var user = buildUser();
        var systemCat = buildSystemCategory(user, "Abonnement", "🔄", SystemCategoryKey.SUBSCRIPTION);
        var catId = systemCat.getId();

        when(categoryRepository.findById(catId)).thenReturn(Optional.of(systemCat));

        assertThatThrownBy(() -> categoryService.delete(catId, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("System categories cannot be deleted");
        verify(categoryRepository, never()).delete(any());
    }

    @Test
    void should_seedSystemCategories_when_newUser() {
        var user = buildUser();
        when(categoryRepository.save(any(Category.class))).thenAnswer(invocation -> invocation.getArgument(0));

        categoryService.seedSystemCategories(user);

        ArgumentCaptor<Category> captor = ArgumentCaptor.forClass(Category.class);
        verify(categoryRepository, org.mockito.Mockito.times(3)).save(captor.capture());
        assertThat(captor.getAllValues())
                .extracting(Category::getSystemKey)
                .containsExactly(SystemCategoryKey.SUBSCRIPTION, SystemCategoryKey.DEBT, SystemCategoryKey.TRANSFER);
    }

    @Test
    void should_findSystemCategory_when_keyAndUserExist() {
        var user = buildUser();
        var systemCat = buildSystemCategory(user, "Abonnement", "🔄", SystemCategoryKey.SUBSCRIPTION);

        when(categoryRepository.findByUserIdAndSystemKey(userId, SystemCategoryKey.SUBSCRIPTION))
                .thenReturn(Optional.of(systemCat));

        Category result = categoryService.findSystemCategory(SystemCategoryKey.SUBSCRIPTION, userId);

        assertThat(result).isNotNull();
        assertThat(result.getNom()).isEqualTo("Abonnement");
        assertThat(result.getIsSystem()).isTrue();
    }

    @Test
    void should_returnNull_when_systemCategoryNotFound() {
        when(categoryRepository.findByUserIdAndSystemKey(userId, SystemCategoryKey.SUBSCRIPTION))
                .thenReturn(Optional.empty());

        Category result = categoryService.findSystemCategory(SystemCategoryKey.SUBSCRIPTION, userId);

        assertThat(result).isNull();
    }

    @Test
    void should_findSystemCategory_when_nomIsNotFrench() {
        // Le cas qui cassait avant KKS-395 : la recherche par nom francais ("Abonnement")
        // echouait si le nom stocke n'etait plus francais. La recherche par cle est
        // independante du nom affiche.
        var user = buildUser();
        var systemCat = buildSystemCategory(user, "Subscription", "🔄", SystemCategoryKey.SUBSCRIPTION);

        when(categoryRepository.findByUserIdAndSystemKey(userId, SystemCategoryKey.SUBSCRIPTION))
                .thenReturn(Optional.of(systemCat));

        Category result = categoryService.findSystemCategory(SystemCategoryKey.SUBSCRIPTION, userId);

        assertThat(result).isNotNull();
        assertThat(result.getNom()).isEqualTo("Subscription");
    }

    @Test
    void should_returnExisting_when_findOrCreateAdjustmentCategoryAlreadyExists() {
        var user = buildUser();
        var existing = buildSystemCategory(user, "Ajustement", "⚖️", SystemCategoryKey.ADJUSTMENT);

        when(categoryRepository.findByUserIdAndSystemKey(userId, SystemCategoryKey.ADJUSTMENT))
                .thenReturn(Optional.of(existing));

        Category result = categoryService.findOrCreateAdjustmentCategory(userId);

        assertThat(result).isEqualTo(existing);
        verify(categoryRepository, never()).save(any());
    }

    @Test
    void should_createAdjustmentCategory_when_notFound() {
        var user = buildUser();

        when(categoryRepository.findByUserIdAndSystemKey(userId, SystemCategoryKey.ADJUSTMENT))
                .thenReturn(Optional.empty());
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(categoryRepository.save(any(Category.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Category result = categoryService.findOrCreateAdjustmentCategory(userId);

        assertThat(result.getNom()).isEqualTo("Ajustement");
        assertThat(result.getIsSystem()).isTrue();
        assertThat(result.getSystemKey()).isEqualTo(SystemCategoryKey.ADJUSTMENT);
        verify(categoryRepository).save(any(Category.class));
    }

    @Test
    void should_mapSystemKeyAndUserCategory_when_getMostUsed() {
        UUID systemCategoryId = UUID.randomUUID();
        UUID userCategoryId = UUID.randomUUID();

        // Colonnes natives : category_id, nom, icone, couleur, is_system, cnt, system_key
        Object[] systemRow = {systemCategoryId, "Abonnement", "🔄", "#6366f1", true, 5L, "SUBSCRIPTION"};
        Object[] userRow = {userCategoryId, "Alimentation", "🍔", "#FF5733", false, 3L, null};

        when(transactionRepository.findMostUsedCategories(eq(userId), any(LocalDate.class), eq(5)))
                .thenReturn(List.of(systemRow, userRow));

        List<CategoryResponse> result = categoryService.getMostUsed(userId, 30, 5);

        assertThat(result).hasSize(2);

        CategoryResponse systemResponse = result.get(0);
        assertThat(systemResponse.id()).isEqualTo(systemCategoryId);
        assertThat(systemResponse.nom()).isEqualTo("Abonnement");
        assertThat(systemResponse.icone()).isEqualTo("🔄");
        assertThat(systemResponse.couleur()).isEqualTo("#6366f1");
        assertThat(systemResponse.isSystem()).isTrue();
        assertThat(systemResponse.systemKey()).isEqualTo("SUBSCRIPTION");

        CategoryResponse userResponse = result.get(1);
        assertThat(userResponse.id()).isEqualTo(userCategoryId);
        assertThat(userResponse.nom()).isEqualTo("Alimentation");
        assertThat(userResponse.icone()).isEqualTo("🍔");
        assertThat(userResponse.couleur()).isEqualTo("#FF5733");
        assertThat(userResponse.isSystem()).isFalse();
        assertThat(userResponse.systemKey()).isNull();
    }
}
