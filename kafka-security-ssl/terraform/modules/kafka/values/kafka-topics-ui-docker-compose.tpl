version: '2'

services:
  # https://github.com/confluentinc/schema-registry
  confluent-schema-registry:
    image: confluentinc/cp-schema-registry:3.2.1
    network_mode: host
    environment:
      SCHEMA_REGISTRY_KAFKASTORE_CONNECTION_URL: __{ZOOKEEPER_DNS}__/kafka
      SCHEMA_REGISTRY_LISTENERS: http://0.0.0.0:8081
      # please replace this setting by the IP of your web tools server
      SCHEMA_REGISTRY_HOST_NAME: "__{HOST_PUBLIC_IP}__"
    restart: always

  # https://github.com/confluentinc/kafka-rest
  confluent-rest-proxy:
    image: confluentinc/cp-kafka-rest:3.2.1
    network_mode: host
    environment:
      KAFKA_REST_BOOTSTRAP_SERVERS: __{KAFKA_DNS}__
      KAFKA_REST_ZOOKEEPER_CONNECT: __{ZOOKEEPER_DNS}__/kafka
      KAFKA_REST_LISTENERS: http://0.0.0.0:8082/
      KAFKA_REST_SCHEMA_REGISTRY_URL: http://localhost:8081/
      # please replace this setting by the IP of your web tools server
      KAFKA_REST_HOST_NAME: "__{HOST_PUBLIC_IP}__"
    depends_on:
      - confluent-schema-registry
    restart: always

  # https://github.com/Landoop/kafka-topics-ui
  kafka-topics-ui:
    image: landoop/kafka-topics-ui:0.9.2
    network_mode: host
    environment:
      KAFKA_REST_PROXY_URL: http://localhost:8082
      PROXY: "TRUE"
    depends_on:
      - confluent-rest-proxy
    restart: always