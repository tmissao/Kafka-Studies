version: '2'

services:
  # https://github.com/yahoo/kafka-manager
  kafka-manager:
    image: qnib/plain-kafka-manager
    network_mode: host
    environment:
      ZOOKEEPER_HOSTS: "__{ZOOKEEPER_DNS}__"
      APPLICATION_SECRET: ${KAFKA_MANAGER_SECRET}
    restart: always