package org.example.interface_adapters.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;

import static org.example.external_interfaces.config.KakfaTopicCreatorExampleConfig.TOPIC_NAME;

@RestController
public class PersonProducerController {

    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;

    @GetMapping("send")
    public ResponseEntity<?> send(){
        kafkaTemplate.send(TOPIC_NAME, "Send mensage:" + LocalDateTime.now());
        return ResponseEntity.ok().build();
    }
}

