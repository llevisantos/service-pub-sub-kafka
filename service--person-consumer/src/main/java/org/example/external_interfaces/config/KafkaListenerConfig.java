package org.example.external_interfaces.config;


import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.stereotype.Component;

@Component
@Slf4j
public class KafkaListenerConfig {

    @KafkaListener(topics = "${kafka.topic-name}", groupId = "${kafka.group-id}")
    public void listen(String mensage,
                       @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
                       @Header(KafkaHeaders.OFFSET) String offset) {
        log.info("Thread: {}", Thread.currentThread().getId());
        log.info("Received topic: {}", topic);
        log.info("Received: {}", mensage);
        log.info("Offiset: {}", offset);
    }

}
