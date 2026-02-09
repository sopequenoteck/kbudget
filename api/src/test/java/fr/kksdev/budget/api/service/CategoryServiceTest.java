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

    @Test
    void should_create_category_when_valid_request() {
        var user = buildUser();
        var request = new CategoryRequest("Alimentation", "\uD83C\uDF54", "#FF5733");
        var saved = buildCategory(user);

        when(categoryRepository.existsByNomAndUserId("Alimentation", userId)).thenReturn(false);
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(categoryRepository.save(any(Category.class))).thenReturn(saved);

        CategoryResponse response = categoryService.create(request, userId);

        assertThat(response.id()).isEqualTo(categoryId);
        assertThat(response.nom()).isEqualTo("Alimentation");
        assertThat(response.icone()).isEqualTo("\uD83C\uDF54");
        assertThat(response.couleur()).isEqualTo("#FF5733");
        verify(categoryRepository).save(any(Category.class));
    }

    @Test
    void should_throw_when_create_with_duplicate_name() {
        var request = new CategoryRequest("Alimentation", "\uD83C\uDF54", "#FF5733");

        when(categoryRepository.existsByNomAndUserId("Alimentation", userId)).thenReturn(true);

        assertThatThrownBy(() -> categoryService.create(request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Une catégorie avec ce nom existe déjà");
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
                .hasMessage("Catégorie non trouvée");
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
        when(categoryRepository.existsByNomAndUserIdAndIdNot("Transport", userId, categoryId)).thenReturn(false);
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
        when(categoryRepository.existsByNomAndUserIdAndIdNot("Transport", userId, categoryId)).thenReturn(true);

        assertThatThrownBy(() -> categoryService.update(categoryId, request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Une catégorie avec ce nom existe déjà");
    }

    @Test
    void should_delete_category_when_found_and_owned() {
        var user = buildUser();
        var category = buildCategory(user);

        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(category));

        categoryService.delete(categoryId, userId);

        verify(categoryRepository).delete(category);
    }
}
