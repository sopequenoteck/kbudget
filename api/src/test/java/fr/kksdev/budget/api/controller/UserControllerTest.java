package fr.kksdev.budget.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import fr.kksdev.budget.api.config.AdminEmailResolver;
import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.config.SecurityConfig;
import fr.kksdev.budget.api.dto.response.AuthResponse;
import fr.kksdev.budget.api.dto.response.UserResponse;
import fr.kksdev.budget.api.exception.AvatarNotFoundException;
import fr.kksdev.budget.api.exception.InvalidImageFormatException;
import fr.kksdev.budget.api.exception.PasswordIncorrectException;
import fr.kksdev.budget.api.exception.PasswordUnchangedException;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.AvatarStorageService;
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
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
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

    // ---- Helpers ----

    private byte[] createJpegBytes() throws Exception {
        BufferedImage img = new BufferedImage(100, 100, BufferedImage.TYPE_INT_RGB);
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ImageIO.write(img, "jpg", baos);
        return baos.toByteArray();
    }
}
