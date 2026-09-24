package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.CategoryRequest;
import fr.kksdev.budget.api.dto.response.CategoryResponse;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CategoryServiceTest {

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private UserRepository userRepository;

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
                .icone("\uD83C\uDF54")
                .couleur("#FF5733")
                .user(user)
                .build();
    }

    private Category buildSystemCategory(User user, String nom, String icone) {
        return Category.builder()
                .id(UUID.randomUUID())
                .nom(nom)
                .icone(icone)
                .couleur("#6366f1")
                .isSystem(true)
                .user(user)
                .build();
    }

    @Test
    void should_create_category_when_valid_request() {
        var user = buildUser();
        var request = new CategoryRequest("Alimentation", "\uD83C\uDF54", "#FF5733");
        var saved = buildCategory(user);

        when(categoryRepository.existsByNomIgnoreCaseAndUserId("Alimentation", userId)).thenReturn(false);
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(categoryRepository.save(any(Category.class))).thenReturn(saved);

        CategoryResponse response = categoryService.create(request, userId);

        assertThat(response.id()).isEqualTo(categoryId);
        assertThat(response.nom()).isEqualTo("Alimentation");
        assertThat(response.icone()).isEqualTo("\uD83C\uDF54");
        assertThat(response.couleur()).isEqualTo("#FF5733");
        assertThat(response.isSystem()).isFalse();
        verify(categoryRepository).save(any(Category.class));
    }

    @Test
    void should_throw_when_create_with_duplicate_name() {
        var request = new CategoryRequest("Alimentation", "\uD83C\uDF54", "#FF5733");

        when(categoryRepository.existsByNomIgnoreCaseAndUserId("Alimentation", userId)).thenReturn(true);

        assertThatThrownBy(() -> categoryService.create(request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("A category with this name already exists");
    }

    @Test
    void should_rejectDuplicate_when_caseInsensitiveName() {
        var request = new CategoryRequest("alimentation", "\uD83C\uDF54", "#FF5733");

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
        var request = new CategoryRequest("Transport", "\uD83D\uDE97", "#3498DB");

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
        var request = new CategoryRequest("Transport", "\uD83D\uDE97", "#3498DB");

        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(existing));
        when(categoryRepository.existsByNomIgnoreCaseAndUserIdAndIdNot("Transport", userId, categoryId)).thenReturn(true);

        assertThatThrownBy(() -> categoryService.update(categoryId, request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("A category with this name already exists");
    }

    @Test
    void should_throw_when_updateSystemCategory() {
        var user = buildUser();
        var systemCat = buildSystemCategory(user, "Abonnement", "\uD83D\uDD04");
        var catId = systemCat.getId();
        var request = new CategoryRequest("Renamed", "\uD83D\uDD04", "#6366f1");

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
        var systemCat = buildSystemCategory(user, "Abonnement", "\uD83D\uDD04");
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

        verify(categoryRepository, org.mockito.Mockito.times(3)).save(any(Category.class));
    }

    @Test
    void should_findSystemCategory_when_nomAndUserExist() {
        var user = buildUser();
        var systemCat = buildSystemCategory(user, "Abonnement", "\uD83D\uDD04");

        when(categoryRepository.findByNomIgnoreCaseAndUserId("Abonnement", userId))
                .thenReturn(Optional.of(systemCat));

        Category result = categoryService.findSystemCategoryByNom("Abonnement", userId);

        assertThat(result).isNotNull();
        assertThat(result.getNom()).isEqualTo("Abonnement");
        assertThat(result.getIsSystem()).isTrue();
    }

    @Test
    void should_returnNull_when_systemCategoryNotFound() {
        when(categoryRepository.findByNomIgnoreCaseAndUserId("NonExistent", userId))
                .thenReturn(Optional.empty());

        Category result = categoryService.findSystemCategoryByNom("NonExistent", userId);

        assertThat(result).isNull();
    }
}
