package org.example.external_interfaces.config;

import org.apache.kafka.clients.admin.AdminClientConfig;
import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.kafka.KafkaProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.core.KafkaAdmin;

import java.util.HashMap;

@Configuration
public class KakfaTopicCreatorExampleConfig {

    public static final String TOPIC_NAME = "${kafka.topic-name}";
    public static final int PARTITIONS = 5;
    @Autowired
    private KafkaProperties kafkaProperties;

    @Bean
    public KafkaAdmin kafkaAdmin() {
        var props = new HashMap<String, Object>();
        props.put(AdminClientConfig.BOOTSTRAP_SERVERS_CONFIG, kafkaProperties.getBootstrapServers());
        return new KafkaAdmin(props);
    }

    @Bean
    public NewTopic newTopic() {
        return new NewTopic(TOPIC_NAME, PARTITIONS, Short.valueOf("1"));
    }
}
