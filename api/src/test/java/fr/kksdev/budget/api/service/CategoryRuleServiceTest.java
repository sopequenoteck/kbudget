package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.exception.ConflictException;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.CategoryRule;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.CategoryRuleRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CategoryRuleServiceTest {

    @Mock
    private CategoryRuleRepository categoryRuleRepository;

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private CategoryRuleService categoryRuleService;

    private final UUID userId = UUID.randomUUID();
    private final UUID categoryId = UUID.randomUUID();
    private final UUID ruleId = UUID.randomUUID();

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

    private CategoryRule buildRule(User user, Category category) {
        return CategoryRule.builder()
                .id(ruleId)
                .user(user)
                .pattern("carrefour")
                .category(category)
                .build();
    }

    @Test
    void should_throw_when_patternIsBlank() {
        assertThatThrownBy(() -> categoryRuleService.create("   ", categoryId, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("The pattern must not be empty");
    }

    @Test
    void should_throw_when_categoryNotFoundOnCreate() {
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> categoryRuleService.create("carrefour", categoryId, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Category not found");
    }

    @Test
    void should_throw_when_categoryBelongsToAnotherUserOnCreate() {
        var otherUser = User.builder().id(UUID.randomUUID()).email("other@mail.com").build();
        var category = buildCategory(otherUser);

        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(category));

        assertThatThrownBy(() -> categoryRuleService.create("carrefour", categoryId, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Category not found");
    }

    @Test
    void should_throw_when_patternAlreadyExists() {
        var user = buildUser();
        var category = buildCategory(user);

        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(category));
        when(categoryRuleRepository.existsByUserIdAndPatternIgnoreCase(userId, "carrefour")).thenReturn(true);

        assertThatThrownBy(() -> categoryRuleService.create("carrefour", categoryId, userId))
                .isInstanceOf(ConflictException.class)
                .hasMessage("A rule with this pattern already exists: carrefour");
    }

    @Test
    void should_throw_when_ruleNotFoundOnUpdate() {
        when(categoryRuleRepository.findByIdAndUserId(ruleId, userId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> categoryRuleService.update(ruleId, "carrefour", categoryId, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Category rule not found");
    }

    @Test
    void should_throw_when_categoryNotFoundOnUpdate() {
        var user = buildUser();
        var category = buildCategory(user);
        var rule = buildRule(user, category);

        when(categoryRuleRepository.findByIdAndUserId(ruleId, userId)).thenReturn(Optional.of(rule));
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> categoryRuleService.update(ruleId, "monoprix", categoryId, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Category not found");
    }

    @Test
    void should_throw_when_ruleNotFoundOnDelete() {
        when(categoryRuleRepository.findByIdAndUserId(ruleId, userId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> categoryRuleService.delete(ruleId, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Category rule not found");
    }
}
