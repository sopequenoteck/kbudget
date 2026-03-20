package fr.kksdev.budget.api.config;

import fr.kksdev.budget.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.MessagingException;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Set;

@Slf4j
@Component
@RequiredArgsConstructor
public class StompAuthInterceptor implements ChannelInterceptor {

    private static final Set<StompCommand> AUTH_REQUIRED_COMMANDS = Set.of(
            StompCommand.SUBSCRIBE, StompCommand.SEND, StompCommand.MESSAGE);

    private final JwtUtil jwtUtil;
    private final UserRepository userRepository;

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        if (accessor != null && StompCommand.CONNECT.equals(accessor.getCommand())) {
            String authHeader = accessor.getFirstNativeHeader("Authorization");
            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                throw new MessagingException("Authorization header manquant");
            }

            String token = authHeader.substring(7);
            if (!jwtUtil.isTokenValid(token)) {
                throw new MessagingException("Token JWT invalide");
            }

            String email = jwtUtil.extractEmail(token);
            var user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new MessagingException("Utilisateur non trouvé"));

            var auth = new UsernamePasswordAuthenticationToken(user.getId(), null, List.of());
            accessor.setUser(auth);
            log.info("STOMP client connecté: userId={}", user.getId());
        } else if (accessor != null && AUTH_REQUIRED_COMMANDS.contains(accessor.getCommand()) && accessor.getUser() == null) {
            throw new MessagingException("Authentification STOMP requise");
        }
        return message;
    }
}
