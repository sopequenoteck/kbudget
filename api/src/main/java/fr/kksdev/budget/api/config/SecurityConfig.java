package fr.kksdev.budget.api.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import fr.kksdev.budget.api.repository.UserRepository;

import java.util.List;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    /** Prefixe de version applique aux controllers par {@link ApiVersioningConfig} (KKS-313). */
    private static final String V = ApiVersioningConfig.CURRENT_VERSION_PREFIX;

    private final JwtFilter jwtFilter;
    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;

    @Bean
    public ApiErrorWriter apiErrorWriter() {
        return new ApiErrorWriter(new ObjectMapper());
    }

    @Bean
    public ApiAuthenticationEntryPoint apiAuthenticationEntryPoint(ApiErrorWriter errorWriter) {
        return new ApiAuthenticationEntryPoint(errorWriter);
    }

    @Bean
    public ApiAccessDeniedHandler apiAccessDeniedHandler(ApiErrorWriter errorWriter) {
        return new ApiAccessDeniedHandler(errorWriter);
    }

    @Value("${app.cors.allowed-origins:http://localhost:4200,http://localhost:49228}")
    private List<String> allowedOrigins;

    @Bean
    public AdminAuthorizationFilter adminAuthorizationFilter(ApiErrorWriter errorWriter) {
        return new AdminAuthorizationFilter(userRepository, errorWriter);
    }

    @Bean
    public PasswordResetRequiredFilter passwordResetRequiredFilter(ApiErrorWriter errorWriter) {
        return new PasswordResetRequiredFilter(jwtUtil, errorWriter);
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http,
                                                   ApiAuthenticationEntryPoint authenticationEntryPoint,
                                                   ApiAccessDeniedHandler accessDeniedHandler,
                                                   ApiErrorWriter errorWriter) throws Exception {
        return http
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        // /auth/first-login-reset nécessite un JWT valide (user avec mustResetCredentials=true)
                        .requestMatchers(V + "/auth/login", V + "/auth/refresh", V + "/auth/logout",
                                V + "/auth/invitations/**", V + "/auth/accept-invite").permitAll()
                        // Les routes springdoc restent en permitAll, mais ne sont mappées
                        // que si springdoc est actif : desactive par defaut, actif en profil
                        // dev ou via SWAGGER_ENABLED=true. Sans mapping elles repondent 404,
                        // ce qui expose moins qu'un 401 sur un chemin retire de cette liste.
                        // /error, /actuator, /bank-logos et /ws ne sont pas des @RestController :
                        // ApiVersioningConfig ne les prefixe pas, leurs chemins sont inchanges.
                        // /meta est public et non versionne (KKS-314) : un client doit
                        // pouvoir verifier la compatibilite avant d'avoir des identifiants,
                        // et l'ecran de configuration serveur s'en sert pour valider l'URL.
                        .requestMatchers("/error", "/meta",
                                "/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html",
                                "/actuator/health", V + "/banks", "/bank-logos/**").permitAll()
                        // WebSocket: auth déléguée au StompAuthInterceptor (CONNECT frame)
                        // car le handshake HTTP ne supporte pas le header Authorization
                        .requestMatchers("/ws/**").permitAll()
                        .anyRequest().authenticated())
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint(authenticationEntryPoint)
                        .accessDeniedHandler(accessDeniedHandler))
                .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class)
                .addFilterAfter(passwordResetRequiredFilter(errorWriter), JwtFilter.class)
                .addFilterAfter(adminAuthorizationFilter(errorWriter), PasswordResetRequiredFilter.class)
                .build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        var config = new CorsConfiguration();
        config.setAllowedOrigins(allowedOrigins);
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowCredentials(true);
        config.setMaxAge(3600L);

        var source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
