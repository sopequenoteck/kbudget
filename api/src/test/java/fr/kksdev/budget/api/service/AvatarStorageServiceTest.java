package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.config.StorageProperties;
import fr.kksdev.budget.api.exception.AvatarNotFoundException;
import fr.kksdev.budget.api.exception.FileTooLargeException;
import fr.kksdev.budget.api.exception.InvalidImageFormatException;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.mock.web.MockMultipartFile;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AvatarStorageServiceTest {

    @TempDir
    Path tempDir;

    @Mock
    private UserRepository userRepository;

    @Mock
    private StorageProperties storageProperties;

    @InjectMocks
    private AvatarStorageService avatarStorageService;

    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = User.builder()
                .id(UUID.randomUUID())
                .email("test@mail.com")
                .name("Test")
                .build();

        StorageProperties.Avatars avatarProps = new StorageProperties.Avatars();
        avatarProps.setPath(tempDir.toString());
        when(storageProperties.getAvatars()).thenReturn(avatarProps);
    }

    // ---- store ----

    @Test
    void should_store_avatar_when_valid_jpeg() throws Exception {
        MockMultipartFile file = new MockMultipartFile("file", "avatar.jpg", "image/jpeg",
                createMinimalJpeg());
        when(userRepository.save(any(User.class))).thenReturn(testUser);

        String path = avatarStorageService.store(testUser, file);

        assertThat(path).endsWith(testUser.getId() + ".jpg");
        assertThat(Files.exists(Path.of(path))).isTrue();
        verify(userRepository).save(testUser);
    }

    @Test
    void should_store_avatar_when_valid_png() throws Exception {
        MockMultipartFile file = new MockMultipartFile("file", "avatar.png", "image/png",
                createMinimalPng());
        when(userRepository.save(any(User.class))).thenReturn(testUser);

        String path = avatarStorageService.store(testUser, file);

        assertThat(path).endsWith(testUser.getId() + ".jpg");
        assertThat(Files.exists(Path.of(path))).isTrue();
    }

    @Test
    void should_throw_when_invalid_mime() {
        byte[] pdfBytes = {0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, 0x0A, 0x25};
        MockMultipartFile file = new MockMultipartFile("file", "malicious.jpg", "image/jpeg", pdfBytes);

        assertThatThrownBy(() -> avatarStorageService.store(testUser, file))
                .isInstanceOf(InvalidImageFormatException.class);
    }

    @Test
    void should_throw_when_file_too_large() {
        byte[] jpegHeader = {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE0};
        byte[] content = new byte[2 * 1024 * 1024 + 1];
        System.arraycopy(jpegHeader, 0, content, 0, jpegHeader.length);
        MockMultipartFile file = new MockMultipartFile("file", "large.jpg", "image/jpeg", content);

        assertThatThrownBy(() -> avatarStorageService.store(testUser, file))
                .isInstanceOf(FileTooLargeException.class);
    }

    @Test
    void should_resize_to_256x256_when_uploading() throws Exception {
        MockMultipartFile file = new MockMultipartFile("file", "avatar.jpg", "image/jpeg",
                createJpegOfSize(512, 512));
        when(userRepository.save(any(User.class))).thenReturn(testUser);

        String path = avatarStorageService.store(testUser, file);

        BufferedImage stored = ImageIO.read(Path.of(path).toFile());
        assertThat(stored.getWidth()).isEqualTo(256);
        assertThat(stored.getHeight()).isEqualTo(256);
    }

    @Test
    void should_compute_consistent_etag_for_same_bytes() {
        byte[] bytes = "test-content".getBytes();

        String etag1 = avatarStorageService.computeEtag(bytes);
        String etag2 = avatarStorageService.computeEtag(bytes);

        assertThat(etag1).isEqualTo(etag2);
        assertThat(etag1).hasSize(8);
    }

    @Test
    void should_delete_avatar_and_nullify_path() throws Exception {
        Path avatarFile = tempDir.resolve(testUser.getId() + ".jpg");
        Files.write(avatarFile, new byte[]{1, 2, 3});
        testUser.setAvatarPath(avatarFile.toString());
        when(userRepository.save(any(User.class))).thenReturn(testUser);

        avatarStorageService.delete(testUser);

        assertThat(Files.exists(avatarFile)).isFalse();
        assertThat(testUser.getAvatarPath()).isNull();
        verify(userRepository).save(testUser);
    }

    @Test
    void should_throw_when_reading_missing_avatar() {
        testUser.setAvatarPath(null);

        assertThatThrownBy(() -> avatarStorageService.read(testUser))
                .isInstanceOf(AvatarNotFoundException.class);
    }

    @Test
    void should_throw_when_reading_avatar_file_not_on_disk() throws Exception {
        testUser.setAvatarPath(tempDir.resolve("nonexistent.jpg").toString());

        assertThatThrownBy(() -> avatarStorageService.read(testUser))
                .isInstanceOf(AvatarNotFoundException.class);
    }

    @Test
    void should_throw_when_deleting_avatar_with_null_path() {
        testUser.setAvatarPath(null);

        assertThatThrownBy(() -> avatarStorageService.delete(testUser))
                .isInstanceOf(AvatarNotFoundException.class);
    }

    // ---- Helpers ----

    private byte[] createMinimalJpeg() throws IOException {
        return createJpegOfSize(100, 100);
    }

    private byte[] createJpegOfSize(int width, int height) throws IOException {
        BufferedImage img = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ImageIO.write(img, "jpg", baos);
        return baos.toByteArray();
    }

    private byte[] createMinimalPng() throws IOException {
        BufferedImage img = new BufferedImage(100, 100, BufferedImage.TYPE_INT_RGB);
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ImageIO.write(img, "png", baos);
        return baos.toByteArray();
    }
}
