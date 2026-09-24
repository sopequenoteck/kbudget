package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.config.StorageProperties;
import fr.kksdev.budget.api.exception.AvatarNotFoundException;
import fr.kksdev.budget.api.exception.FileTooLargeException;
import fr.kksdev.budget.api.exception.InvalidImageFormatException;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.util.ImageMimeValidator;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import net.coobird.thumbnailator.Thumbnails;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

@Slf4j
@Service
@RequiredArgsConstructor
public class AvatarStorageService {

    private static final long MAX_SIZE_BYTES = 2L * 1024 * 1024; // 2 MB

    private final StorageProperties storageProperties;
    private final UserRepository userRepository;

    @PostConstruct
    public void init() {
        try {
            Files.createDirectories(Path.of(storageProperties.getAvatars().getPath()));
        } catch (IOException e) {
            throw new RuntimeException("Unable to create the avatar storage directory", e);
        }
    }

    @Transactional
    public String store(User user, MultipartFile file) {
        if (!ImageMimeValidator.isValidImage(file)) {
            throw new InvalidImageFormatException();
        }
        if (file.getSize() > MAX_SIZE_BYTES) {
            throw new FileTooLargeException();
        }

        Path avatarPath = Path.of(storageProperties.getAvatars().getPath())
                .resolve(user.getId() + ".jpg");

        try {
            Thumbnails.of(file.getInputStream())
                    .size(256, 256)
                    .outputFormat("jpg")
                    .outputQuality(0.85)
                    .toFile(avatarPath.toFile());
        } catch (IOException e) {
            log.error("Erreur lors du stockage de l'avatar pour userId={}", user.getId(), e);
            throw new RuntimeException("Failed to store the avatar", e);
        }

        user.setAvatarPath(avatarPath.toString());
        userRepository.save(user);

        log.info("Avatar uploaded for user {}", user.getId());
        return avatarPath.toString();
    }

    public byte[] read(User user) {
        if (user.getAvatarPath() == null) {
            throw new AvatarNotFoundException();
        }
        Path path = Path.of(user.getAvatarPath());
        if (!Files.exists(path)) {
            throw new AvatarNotFoundException();
        }
        try {
            return Files.readAllBytes(path);
        } catch (IOException e) {
            log.error("Erreur lors de la lecture de l'avatar pour userId={}", user.getId(), e);
            throw new RuntimeException("Failed to read the avatar", e);
        }
    }

    public String computeEtag(byte[] avatarBytes) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(avatarBytes);
            StringBuilder hex = new StringBuilder();
            for (byte b : hash) {
                hex.append(String.format("%02x", b));
            }
            return hex.substring(0, 8);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 is not available", e);
        }
    }

    @Transactional
    public void delete(User user) {
        if (user.getAvatarPath() == null) {
            throw new AvatarNotFoundException();
        }
        try {
            Files.deleteIfExists(Path.of(user.getAvatarPath()));
        } catch (IOException e) {
            log.error("Erreur lors de la suppression de l'avatar pour userId={}", user.getId(), e);
            throw new RuntimeException("Failed to delete the avatar", e);
        }
        user.setAvatarPath(null);
        userRepository.save(user);
        log.info("Avatar deleted for user {}", user.getId());
    }
}
