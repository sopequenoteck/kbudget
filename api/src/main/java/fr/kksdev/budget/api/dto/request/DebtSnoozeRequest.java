package fr.kksdev.budget.api.dto.request;

import jakarta.validation.constraints.FutureOrPresent;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;
import java.time.LocalTime;

public record DebtSnoozeRequest(
        @NotNull @FutureOrPresent LocalDate reminderDate,
        @NotNull LocalTime reminderTime
) {}
