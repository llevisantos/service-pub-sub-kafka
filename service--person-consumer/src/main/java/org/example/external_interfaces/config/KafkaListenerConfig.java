package org.example.external_interfaces.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
@Slf4j
public class KafkaListenerConfig {

    @KafkaListener(topics = "topic-person-info", groupId = "service-person")
    public void listen(String mensage){
        log.info("Thread: {}", Thread.currentThread().getId());
        log.info("Received: {}", mensage);
    }

}
