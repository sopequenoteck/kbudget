package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.UpdateProfileRequest;
import fr.kksdev.budget.api.dto.response.UserResponse;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserService userService;

    private final UUID userId = UUID.randomUUID();

    private User buildUser() {
        return User.builder().id(userId).email("test@mail.com").name("Old name").build();
    }

    @Test
    void should_update_name_and_return_profile_when_name_is_provided() {
        var user = buildUser();
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(userRepository.save(user)).thenReturn(user);

        UserResponse response = userService.updateProfile(userId, new UpdateProfileRequest("New name"));

        assertThat(response.name()).isEqualTo("New name");
        assertThat(response.email()).isEqualTo("test@mail.com");
        verify(userRepository).save(user);
    }

    @Test
    void should_keep_name_when_requested_name_is_null() {
        var user = buildUser();
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(userRepository.save(user)).thenReturn(user);

        UserResponse response = userService.updateProfile(userId, new UpdateProfileRequest(null));

        assertThat(response.name()).isEqualTo("Old name");
    }

    @Test
    void should_throw_when_user_not_found_on_get_profile() {
        when(userRepository.findById(userId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> userService.getProfile(userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("User not found");
    }
}
