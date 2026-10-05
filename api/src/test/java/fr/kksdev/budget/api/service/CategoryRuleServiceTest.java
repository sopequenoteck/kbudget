package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.enums.CategoryRuleOrigin;
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

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.verify;
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

    @Test
    void should_update_pattern_and_category_when_rule_and_category_are_owned() {
        var user = buildUser();
        var rule = buildRule(user, buildCategory(user));
        UUID newCategoryId = UUID.randomUUID();
        var newCategory = Category.builder().id(newCategoryId).nom("Loisirs").user(user).build();

        when(categoryRuleRepository.findByIdAndUserId(ruleId, userId)).thenReturn(Optional.of(rule));
        when(categoryRepository.findById(newCategoryId)).thenReturn(Optional.of(newCategory));
        when(categoryRuleRepository.save(rule)).thenReturn(rule);

        var response = categoryRuleService.update(ruleId, "monoprix", newCategoryId, userId);

        assertThat(response.pattern()).isEqualTo("monoprix");
        assertThat(response.categoryId()).isEqualTo(newCategoryId);
        assertThat(rule.getCategory()).isSameAs(newCategory);
        verify(categoryRuleRepository).save(rule);
    }

    @Test
    void should_delete_rule_when_rule_is_owned() {
        var user = buildUser();
        var rule = buildRule(user, buildCategory(user));

        when(categoryRuleRepository.findByIdAndUserId(ruleId, userId)).thenReturn(Optional.of(rule));

        categoryRuleService.delete(ruleId, userId);

        verify(categoryRuleRepository).delete(rule);
    }

    // -------------------------------------------------------------------------
    // firstMatch (KKS-387)
    // -------------------------------------------------------------------------

    private CategoryRule ruleOf(String pattern, CategoryRuleOrigin origin, String categoryName) {
        return CategoryRule.builder()
                .pattern(pattern)
                .origin(origin)
                .category(Category.builder().id(UUID.randomUUID()).nom(categoryName).build())
                .build();
    }

    @Test
    void should_return_the_category_of_the_first_matching_rule_in_the_order_given() {
        CategoryRule typed = ruleOf("carre", CategoryRuleOrigin.MANUAL, "Typed");
        CategoryRule automatic = ruleOf("CARREFOUR MARKET", CategoryRuleOrigin.AUTO, "Automatic");

        assertThat(CategoryRuleService.firstMatch(List.of(typed, automatic), "Carrefour Market 12/09"))
                .contains(typed.getCategory());
        assertThat(CategoryRuleService.firstMatch(List.of(automatic, typed), "Carrefour Market 12/09"))
                .contains(automatic.getCategory());
    }

    @Test
    void should_match_an_automatic_rule_on_whole_words_only() {
        CategoryRule automatic = ruleOf("FRESH", CategoryRuleOrigin.AUTO, "Automatic");

        assertThat(CategoryRuleService.firstMatch(List.of(automatic), "FRESH FRUITS")).isPresent();
        assertThat(CategoryRuleService.firstMatch(List.of(automatic), "REFRESHMENT")).isEmpty();
    }

    @Test
    void should_return_nothing_when_no_rule_matches_or_the_label_is_null() {
        CategoryRule typed = ruleOf("carrefour", CategoryRuleOrigin.MANUAL, "Typed");

        assertThat(CategoryRuleService.firstMatch(List.of(typed), "Boulangerie")).isEmpty();
        assertThat(CategoryRuleService.firstMatch(List.of(typed), null)).isEmpty();
        assertThat(CategoryRuleService.firstMatch(List.of(), "Carrefour")).isEmpty();
    }
}
