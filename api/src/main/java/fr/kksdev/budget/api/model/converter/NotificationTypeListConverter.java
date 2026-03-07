package fr.kksdev.budget.api.model.converter;

import fr.kksdev.budget.api.enums.NotificationType;
import jakarta.persistence.Converter;

@Converter
public class NotificationTypeListConverter extends AbstractEnumListConverter<NotificationType> {
    public NotificationTypeListConverter() {
        super(NotificationType.class);
    }
}
