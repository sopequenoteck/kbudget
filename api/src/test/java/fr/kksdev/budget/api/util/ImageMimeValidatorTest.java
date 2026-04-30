package fr.kksdev.budget.api.util;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

import static org.assertj.core.api.Assertions.assertThat;

class ImageMimeValidatorTest {

    @Test
    void should_accept_when_jpeg_magic_number_valid() {
        byte[] jpegContent = new byte[]{
                (byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE0,
                0x00, 0x10, 0x4A, 0x46, 0x49, 0x46
        };
        var file = new MockMultipartFile("file", "avatar.jpg", "image/jpeg", jpegContent);

        assertThat(ImageMimeValidator.isValidImage(file)).isTrue();
        assertThat(ImageMimeValidator.detectMimeType(file)).isEqualTo("image/jpeg");
    }

    @Test
    void should_accept_when_png_magic_number_valid() {
        byte[] pngContent = new byte[]{
                (byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
                0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52
        };
        var file = new MockMultipartFile("file", "avatar.png", "image/png", pngContent);

        assertThat(ImageMimeValidator.isValidImage(file)).isTrue();
        assertThat(ImageMimeValidator.detectMimeType(file)).isEqualTo("image/png");
    }

    @Test
    void should_reject_when_gif_mime() {
        // Magic numbers GIF : 47 49 46 38
        byte[] gifContent = new byte[]{
                0x47, 0x49, 0x46, 0x38, 0x39, 0x61,
                0x01, 0x00, 0x01, 0x00
        };
        var file = new MockMultipartFile("file", "animation.gif", "image/gif", gifContent);

        assertThat(ImageMimeValidator.isValidImage(file)).isFalse();
        assertThat(ImageMimeValidator.detectMimeType(file)).isNull();
    }

    @Test
    void should_reject_when_file_renamed_with_jpg_extension_but_pdf_content() {
        // Magic numbers PDF : 25 50 44 46
        byte[] pdfContent = new byte[]{
                0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34,
                0x0A, 0x25
        };
        var file = new MockMultipartFile("file", "malicious.jpg", "image/jpeg", pdfContent);

        assertThat(ImageMimeValidator.isValidImage(file)).isFalse();
        assertThat(ImageMimeValidator.detectMimeType(file)).isNull();
    }

    @Test
    void should_reject_when_file_empty() {
        var emptyFile = new MockMultipartFile("file", "empty.jpg", "image/jpeg", new byte[0]);

        assertThat(ImageMimeValidator.isValidImage(emptyFile)).isFalse();
        assertThat(ImageMimeValidator.detectMimeType(emptyFile)).isNull();
    }
}
