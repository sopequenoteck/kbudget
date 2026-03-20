package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.service.NotificationScheduler;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Profile;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/dev")
@RequiredArgsConstructor
@Profile("dev")
public class DevController {

    private final NotificationScheduler notificationScheduler;

    @PostMapping("/notifications/trigger-daily-job")
    public ResponseEntity<Void> triggerDailyJob() {
        notificationScheduler.runDailyJob();
        return ResponseEntity.ok().build();
    }
}
