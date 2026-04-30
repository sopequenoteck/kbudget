package fr.kksdev.budget.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import fr.kksdev.budget.api.config.AdminEmailResolver;
import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.config.SecurityConfig;
import fr.kksdev.budget.api.dto.response.AuthResponse;
import fr.kksdev.budget.api.dto.response.UserExportResponse;
import fr.kksdev.budget.api.dto.response.UserResponse;
import fr.kksdev.budget.api.exception.AvatarNotFoundException;
import fr.kksdev.budget.api.exception.ConfirmationRequiredException;
import fr.kksdev.budget.api.exception.InvalidImageFormatException;
import fr.kksdev.budget.api.exception.LastAdminDeletionForbiddenException;
import fr.kksdev.budget.api.exception.PasswordIncorrectException;
import fr.kksdev.budget.api.exception.PasswordUnchangedException;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.AvatarStorageService;
import fr.kksdev.budget.api.service.UserDeletionService;
import fr.kksdev.budget.api.service.UserExportService;
import fr.kksdev.budget.api.service.UserPasswordService;
import fr.kksdev.budget.api.service.UserService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(UserController.class)
@Import(SecurityConfig.class)
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private UserService userService;

    @MockitoBean
    private AvatarStorageService avatarStorageService;

    @MockitoBean
    private UserPasswordService userPasswordService;

    @MockitoBean
    private UserExportService userExportService;

    @MockitoBean
    private UserDeletionService userDeletionService;

    @MockitoBean
    private JwtUtil jwtUtil;

    @MockitoBean
    private UserRepository userRepository;

    @MockitoBean
    private AdminEmailResolver adminEmailResolver;

    private static final String BEARER_TOKEN = "Bearer test-token";
    private final UUID userId = UUID.randomUUID();
    private final ObjectMapper objectMapper = new ObjectMapper();
    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = User.builder().id(userId).email("test@mail.com").name("Test").build();
        when(jwtUtil.isTokenValid("test-token")).thenReturn(true);
        when(jwtUtil.extractEmail("test-token")).thenReturn("test@mail.com");
        when(userRepository.findByEmailAndDisabledAtIsNull("test@mail.com")).thenReturn(Optional.of(testUser));
        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));
        when(userService.findById(userId)).thenReturn(testUser);
    }

    // ---- GET /users/me ----

    @Test
    void should_returnProfile_when_authenticated() throws Exception {
        var response = new UserResponse("Test", "test@mail.com", false);
        when(userService.getProfile(userId)).thenReturn(response);

        mockMvc.perform(get("/users/me")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Test"))
                .andExpect(jsonPath("$.email").value("test@mail.com"))
                .andExpect(jsonPath("$.isAdmin").value(false));
    }

    @Test
    void should_return401_when_notAuthenticated() throws Exception {
        mockMvc.perform(get("/users/me"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void should_return_isAdmin_true_when_user_email_in_admin_list() throws Exception {
        var response = new UserResponse("Admin", "admin@mail.com", true);
        when(userService.getProfile(userId)).thenReturn(response);

        mockMvc.perform(get("/users/me")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isAdmin").value(true));
    }

    @Test
    void should_return_isAdmin_false_when_user_email_not_admin() throws Exception {
        var response = new UserResponse("User", "user@mail.com", false);
        when(userService.getProfile(userId)).thenReturn(response);

        mockMvc.perform(get("/users/me")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isAdmin").value(false));
    }

    // ---- PUT /users/me ----

    @Test
    void should_updateName_when_validRequest() throws Exception {
        var response = new UserResponse("Updated", "test@mail.com", false);
        when(userService.updateProfile(eq(userId), any())).thenReturn(response);

        mockMvc.perform(put("/users/me")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name": "Updated"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Updated"));
    }

    // ---- POST /users/me/avatar ----

    @Test
    void should_upload_avatar_when_valid_jpg() throws Exception {
        byte[] jpegBytes = createJpegBytes();
        MockMultipartFile file = new MockMultipartFile("file", "avatar.jpg", "image/jpeg", jpegBytes);
        when(avatarStorageService.read(any(User.class))).thenReturn(jpegBytes);
        when(avatarStorageService.computeEtag(jpegBytes)).thenReturn("a3f5b2c1");

        mockMvc.perform(multipart("/users/me/avatar")
                        .file(file)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.url").value("/api/users/me/avatar"))
                .andExpect(jsonPath("$.etag").value("a3f5b2c1"))
                .andExpect(jsonPath("$.uploadedAt").isNotEmpty());
    }

    @Test
    void should_reject_when_invalid_mime() throws Exception {
        byte[] pdfBytes = {0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, 0x0A, 0x25};
        MockMultipartFile file = new MockMultipartFile("file", "malicious.jpg", "image/jpeg", pdfBytes);
        doThrow(new InvalidImageFormatException()).when(avatarStorageService).store(any(), any());

        mockMvc.perform(multipart("/users/me/avatar")
                        .file(file)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("INVALID_IMAGE_FORMAT"));
    }

    @Test
    void should_serve_avatar_with_etag() throws Exception {
        byte[] jpegBytes = createJpegBytes();
        testUser.setAvatarPath("/tmp/avatar.jpg");
        when(avatarStorageService.read(any(User.class))).thenReturn(jpegBytes);
        when(avatarStorageService.computeEtag(jpegBytes)).thenReturn("a3f5b2c1");

        mockMvc.perform(get("/users/me/avatar")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(header().string("ETag", "\"a3f5b2c1\""))
                .andExpect(content().contentType(MediaType.IMAGE_JPEG));
    }

    @Test
    void should_return_304_when_etag_matches() throws Exception {
        byte[] jpegBytes = createJpegBytes();
        testUser.setAvatarPath("/tmp/avatar.jpg");
        when(avatarStorageService.read(any(User.class))).thenReturn(jpegBytes);
        when(avatarStorageService.computeEtag(jpegBytes)).thenReturn("a3f5b2c1");

        mockMvc.perform(get("/users/me/avatar")
                        .header("Authorization", BEARER_TOKEN)
                        .header("If-None-Match", "\"a3f5b2c1\""))
                .andExpect(status().isNotModified());
    }

    @Test
    void should_delete_avatar_when_authenticated() throws Exception {
        testUser.setAvatarPath("/tmp/avatar.jpg");

        mockMvc.perform(delete("/users/me/avatar")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNoContent());
    }

    @Test
    void should_return_404_when_avatar_not_found() throws Exception {
        when(avatarStorageService.read(any(User.class))).thenThrow(new AvatarNotFoundException());

        mockMvc.perform(get("/users/me/avatar")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("AVATAR_NOT_FOUND"));
    }

    // ---- POST /users/me/password ----

    @Test
    void should_change_password_when_valid() throws Exception {
        AuthResponse authResponse = new AuthResponse("new-jwt", "new-refresh", "test@mail.com", "Test", false);
        when(userPasswordService.changePassword(any(User.class), any())).thenReturn(authResponse);

        mockMvc.perform(post("/users/me/password")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "currentPassword": "OldPassword123!",
                                  "newPassword": "NewPassword123!"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("new-jwt"))
                .andExpect(jsonPath("$.refreshToken").value("new-refresh"))
                .andExpect(jsonPath("$.email").value("test@mail.com"));
    }

    @Test
    void should_reject_when_current_incorrect() throws Exception {
        when(userPasswordService.changePassword(any(User.class), any()))
                .thenThrow(new PasswordIncorrectException());

        mockMvc.perform(post("/users/me/password")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "currentPassword": "WrongPassword1!",
                                  "newPassword": "NewPassword123!"
                                }
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("PASSWORD_INCORRECT"));
    }

    @Test
    void should_reject_when_new_too_short() throws Exception {
        mockMvc.perform(post("/users/me/password")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "currentPassword": "OldPassword123!",
                                  "newPassword": "short"
                                }
                                """))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_reject_when_new_equals_current() throws Exception {
        when(userPasswordService.changePassword(any(User.class), any()))
                .thenThrow(new PasswordUnchangedException());

        mockMvc.perform(post("/users/me/password")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "currentPassword": "SamePassword123!",
                                  "newPassword": "SamePassword123!"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("PASSWORD_UNCHANGED"));
    }

    // ---- GET /users/me/export ----

    @Test
    void should_export_json_when_format_json() throws Exception {
        UserExportResponse exportResponse = new UserExportResponse(
                "1.0.0",
                Instant.now(),
                new UserExportResponse.UserDto(userId.toString(), "test@mail.com", "Test", false, false, null, null),
                null,
                List.of(), List.of(), List.of(), List.of(), List.of(),
                List.of(), List.of(), List.of(), List.of(), List.of(), List.of()
        );
        when(userExportService.exportJson(any(User.class))).thenReturn(exportResponse);

        mockMvc.perform(get("/users/me/export")
                        .param("format", "json")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Disposition", org.hamcrest.Matchers.containsString("kbudget-export-")))
                .andExpect(header().string("Content-Disposition", org.hamcrest.Matchers.containsString(".json")))
                .andExpect(jsonPath("$.schemaVersion").value("1.0.0"));
    }

    @Test
    void should_reject_when_format_invalid() throws Exception {
        mockMvc.perform(get("/users/me/export")
                        .param("format", "xml")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("INVALID_EXPORT_FORMAT"));
    }

    @Test
    void should_reject_when_unauthenticated_on_export() throws Exception {
        mockMvc.perform(get("/users/me/export")
                        .param("format", "json"))
                .andExpect(status().isUnauthorized());
    }

    // Note : le format CSV utilise StreamingResponseBody qui n'est pas rendu nativement par MockMvc
    // Les tests CSV (BOM, traduction type, contenu) sont couverts par UserExportServiceTest

    // ---- DELETE /users/me ----

    @Test
    void should_return_204_when_delete_account_success() throws Exception {
        mockMvc.perform(delete("/users/me")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "currentPassword": "CorrectPassword1!",
                                  "confirmed": true
                                }
                                """))
                .andExpect(status().isNoContent());

        verify(userDeletionService).softDelete(any(User.class), any());
    }

    @Test
    void should_return_400_when_not_confirmed() throws Exception {
        // confirmed=false déclenche la validation Bean (@AssertTrue) avant le service
        mockMvc.perform(delete("/users/me")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "currentPassword": "CorrectPassword1!",
                                  "confirmed": false
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("Confirmation explicite requise")));
    }

    @Test
    void should_return_401_when_password_incorrect() throws Exception {
        doThrow(new PasswordIncorrectException()).when(userDeletionService).softDelete(any(User.class), any());

        mockMvc.perform(delete("/users/me")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "currentPassword": "WrongPassword1!",
                                  "confirmed": true
                                }
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("PASSWORD_INCORRECT"));
    }

    @Test
    void should_return_403_when_last_admin() throws Exception {
        doThrow(new LastAdminDeletionForbiddenException()).when(userDeletionService).softDelete(any(User.class), any());

        mockMvc.perform(delete("/users/me")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "currentPassword": "CorrectPassword1!",
                                  "confirmed": true
                                }
                                """))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").value("LAST_ADMIN_DELETION_FORBIDDEN"))
                .andExpect(jsonPath("$.message").value("Au moins un administrateur actif doit exister."));
    }

    // ---- Helpers ----

    private byte[] createJpegBytes() throws Exception {
        BufferedImage img = new BufferedImage(100, 100, BufferedImage.TYPE_INT_RGB);
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ImageIO.write(img, "jpg", baos);
        return baos.toByteArray();
    }
}
