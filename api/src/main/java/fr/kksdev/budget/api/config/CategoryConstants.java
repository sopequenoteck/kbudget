package fr.kksdev.budget.api.config;

import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

public final class CategoryConstants {

    private CategoryConstants() {}

    public static final List<String> COLORS = List.of(
            "#ef4444", "#f97316", "#f59e0b", "#84cc16",
            "#22c55e", "#14b8a6", "#06b6d4", "#3b82f6",
            "#6366f1", "#8b5cf6", "#ec4899", "#78716c"
    );

    public static String randomColor() {
        return COLORS.get(ThreadLocalRandom.current().nextInt(COLORS.size()));
    }
}
