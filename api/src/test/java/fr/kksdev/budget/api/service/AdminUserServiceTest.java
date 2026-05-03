package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.config.AdminEmailResolver;
import fr.kksdev.budget.api.dto.response.AdminUserResponse;
import fr.kksdev.budget.api.exception.ConflictException;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AdminUserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private AdminEmailResolver adminEmailResolver;

    @InjectMocks
    private AdminUserService adminUserService;

    // ---- list() ----

    @Test
    void should_list_all_users_sorted_by_created_at_with_isAdmin_flag() {
        UUID id1 = UUID.randomUUID();
        UUID id2 = UUID.randomUUID();
        User user1 = User.builder().id(id1).email("admin@test.fr").name("Admin")
                .createdAt(LocalDateTime.now().minusDays(2)).build();
        User user2 = User.builder().id(id2).email("user@test.fr").name("User")
                .createdAt(LocalDateTime.now().minusDays(1)).build();

        when(userRepository.findAll()).thenReturn(List.of(user2, user1));
        when(adminEmailResolver.isAdminEmail("admin@test.fr")).thenReturn(true);
        when(adminEmailResolver.isAdminEmail("user@test.fr")).thenReturn(false);

        List<AdminUserResponse> result = adminUserService.list();

        assertThat(result).hasSize(2);
        assertThat(result.get(0).email()).isEqualTo("admin@test.fr");
        assertThat(result.get(0).isAdmin()).isTrue();
        assertThat(result.get(1).email()).isEqualTo("user@test.fr");
        assertThat(result.get(1).isAdmin()).isFalse();
    }

    // ---- disable() ----

    @Test
    void should_disable_user_when_not_admin_and_set_disabled_at() {
        UUID userId = UUID.randomUUID();
        User target = User.builder().id(userId).email("user@test.fr").build();
        User admin = User.builder().id(UUID.randomUUID()).email("admin@test.fr").build();

        when(userRepository.findById(userId)).thenReturn(Optional.of(target));
        when(adminEmailResolver.isAdminEmail("user@test.fr")).thenReturn(false);

        adminUserService.disable(userId, admin);

        assertThat(target.getDisabledAt()).isNotNull();
        verify(userRepository).save(target);
    }

    @Test
    void should_throw_entity_not_found_when_user_missing_for_disable() {
        UUID userId = UUID.randomUUID();
        User admin = User.builder().id(UUID.randomUUID()).email("admin@test.fr").build();

        when(userRepository.findById(userId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> adminUserService.disable(userId, admin))
                .isInstanceOf(EntityNotFoundException.class);
        verify(userRepository, never()).save(any());
    }

    @Test
    void should_disable_non_admin_without_checking_admin_count() {
        UUID userId = UUID.randomUUID();
        User target = User.builder().id(userId).email("user@test.fr").build();
        User admin = User.builder().id(UUID.randomUUID()).email("admin@test.fr").build();

        when(userRepository.findById(userId)).thenReturn(Optional.of(target));
        when(adminEmailResolver.isAdminEmail("user@test.fr")).thenReturn(false);

        adminUserService.disable(userId, admin);

        // findAll ne doit pas être appelé car le target n'est pas admin
        verify(userRepository, never()).findAll();
        assertThat(target.getDisabledAt()).isNotNull();
    }

    // ---- enable() ----

    @Test
    void should_enable_user_and_clear_disabled_at() {
        UUID userId = UUID.randomUUID();
        User target = User.builder().id(userId).email("user@test.fr")
                .disabledAt(LocalDateTime.now().minusHours(1)).build();
        User admin = User.builder().id(UUID.randomUUID()).email("admin@test.fr").build();

        when(userRepository.findById(userId)).thenReturn(Optional.of(target));

        adminUserService.enable(userId, admin);

        assertThat(target.getDisabledAt()).isNull();
        verify(userRepository).save(target);
    }

    @Test
    void should_throw_entity_not_found_when_user_missing_for_enable() {
        UUID userId = UUID.randomUUID();
        User admin = User.builder().id(UUID.randomUUID()).email("admin@test.fr").build();

        when(userRepository.findById(userId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> adminUserService.enable(userId, admin))
                .isInstanceOf(EntityNotFoundException.class);
        verify(userRepository, never()).save(any());
    }

    @Test
    void should_clear_disabled_at_when_enable_allowing_reauthentication() {
        User disabled = User.builder()
                .id(UUID.randomUUID())
                .email("u@test.fr")
                .disabledAt(LocalDateTime.now().minusHours(1))
                .build();
        when(userRepository.findById(disabled.getId())).thenReturn(Optional.of(disabled));

        User admin = User.builder().id(UUID.randomUUID()).email("admin@test.fr").build();

        adminUserService.enable(disabled.getId(), admin);

        assertThat(disabled.getDisabledAt()).isNull();
        verify(userRepository).save(disabled);
    }

    // ---- garde-fou dernier admin ----

    @Test
    void should_throw_conflict_when_self_disable_is_last_active_admin() {
        UUID adminId = UUID.randomUUID();
        User admin = User.builder()
                .id(adminId)
                .email("admin@test.fr")
                .build();
        when(userRepository.findById(adminId)).thenReturn(Optional.of(admin));
        when(userRepository.findAll()).thenReturn(List.of(admin));
        when(adminEmailResolver.isAdminEmail("admin@test.fr")).thenReturn(true);

        assertThatThrownBy(() -> adminUserService.disable(adminId, admin))
                .isInstanceOf(ConflictException.class)
                .hasMessage("LAST_ADMIN_CANNOT_BE_DISABLED");
        verify(userRepository, never()).save(any());
    }

    @Test
    void should_allow_self_disable_when_other_active_admin_exists() {
        UUID adminId = UUID.randomUUID();
        User admin1 = User.builder().id(adminId).email("admin1@test.fr").build();
        User admin2 = User.builder().id(UUID.randomUUID()).email("admin2@test.fr").build();

        when(userRepository.findById(adminId)).thenReturn(Optional.of(admin1));
        when(userRepository.findAll()).thenReturn(List.of(admin1, admin2));
        when(adminEmailResolver.isAdminEmail("admin1@test.fr")).thenReturn(true);
        when(adminEmailResolver.isAdminEmail("admin2@test.fr")).thenReturn(true);

        adminUserService.disable(adminId, admin1);

        assertThat(admin1.getDisabledAt()).isNotNull();
        verify(userRepository).save(admin1);
    }

    @Test
    void should_not_count_disabled_admins_as_active() {
        UUID admin1Id = UUID.randomUUID();
        User admin1 = User.builder().id(admin1Id).email("admin1@test.fr").build();
        User admin2Disabled = User.builder()
                .id(UUID.randomUUID())
                .email("admin2@test.fr")
                .disabledAt(LocalDateTime.now().minusHours(1))
                .build();

        when(userRepository.findById(admin1Id)).thenReturn(Optional.of(admin1));
        when(userRepository.findAll()).thenReturn(List.of(admin1, admin2Disabled));
        when(adminEmailResolver.isAdminEmail("admin1@test.fr")).thenReturn(true);
        // admin2Disabled est filtré par disabledAt != null avant l'appel isAdminEmail — pas de stub nécessaire

        assertThatThrownBy(() -> adminUserService.disable(admin1Id, admin1))
                .isInstanceOf(ConflictException.class);
    }
}
