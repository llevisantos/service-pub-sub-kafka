package org.example.external_interfaces.config;


import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.stereotype.Component;

@Component
@Slf4j
public class KafkaListenerConfig {

    @KafkaListener(topics = "topic-person-info", groupId = "service-person")
    public void listen(String mensage,
                       @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
                       @Header(KafkaHeaders.OFFSET) String offset,
                       @Header(KafkaHeaders.RECEIVED_PARTITION) int partition) {
        log.info("Thread: {}", Thread.currentThread().getId());
        log.info("Received topic: {}", topic);
        log.info("Received: {}", mensage);
        log.info("Offiset: {}", offset);
        log.info("Partition ID: {}", partition);
    }

}
