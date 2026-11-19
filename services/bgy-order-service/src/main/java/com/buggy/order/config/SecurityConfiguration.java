package com.buggy.order.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration(proxyBeanMethods = false)
class SecurityConfiguration {
    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        return http.authorizeHttpRequests(requests -> requests
                .requestMatchers(HttpMethod.GET, "/actuator/health", "/actuator/health/liveness",
                        "/actuator/health/readiness", "/openapi/v1.yaml").permitAll()
                .anyRequest().denyAll())
                .build();
    }
}
