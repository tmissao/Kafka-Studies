# Kafka Security SSL

This project intends to build a Kafka Cluster configuring encryption (SSL) between the Broker and the Clients

## Prerequisites
---
- [Install TF_ENV](https://github.com/tfutils/tfenv)

## Setup Kafka
---
```bash
cd terraform
tfenv install
tfenv use
terraform apply
```

## Setup Client (SSL)
---

To setup client encrypted communication with the broker, following this steps:

1. Import the Public Certificate
```bash
export CLIPASS=clientpass
# ca-cert is located at .terraform/modules/kafka/keys/ssl/ca-cert
keytool -keystore kafka.client.truststore.jks -alias CARoot -import -file ca-cert  -storepass $CLIPASS -keypass $CLIPASS -noprompt
```

2. Create the client.properties file
```
security.protocol=SSL
# Path to client.truststore.jks
ssl.truststore.location=client.truststore.jks 
ssl.truststore.password=clientpass
```

3. Run the producer and consummer with client.properties configuration
```bash
# Create Topic
kafka-topics.sh --zookeeper <zookeeper-dns> --create --topic kafka-security-topic --replication-factor 1 --partitions 2

# Producer
kafka-console-producer.sh --broker-list <broker-dns>:9093 --topic kafka-security-topic --producer.config client.properties

# Consumer
kafka-console-consumer.sh --bootstrap-server <broker-dns>:9093 --topic kafka-security-topic --consumer.config client.properties
```

## Setup SSL Authentication
---

To setup SSL authentication it is necessary to pass the property `ssl.client.auth=required` on Kafka Broker. This is archieved by running terraform with `variable ssl_authentication_enabled = true`.

Also, it is necessary to configure the client with a signed certificate, thus both broker and client will have their certificates validated (Two-Way Authentication). To create a signed certificate for the client follow these steps:

1. Create a signed Certificate
```bash
# Creates a KeyStore
export CLIPASS=clientpass
export SRVPASS=serversecret

keytool -genkey -keystore kafka.client.keystore.jks -validity 365 -storepass $CLIPASS -keypass $CLIPASS  -dname "CN=mylaptop" -alias my-local-pc

# Creates a Certificate Request
keytool -keystore kafka.client.keystore.jks -certreq -file client-cert-sign-request -alias my-local-pc -storepass $CLIPASS -keypass $CLIPASS

# Signs the certificate
# ca-cert is located at .terraform/modules/kafka/keys/ssl/ca-cert
# ca-key is located at .terraform/modules/kafka/keys/ssl/ca-key
openssl x509 -req -CA ca-cert -CAkey ca-key -in client-cert-sign-request -out client-cert-signed -days 365 -CAcreateserial -passin pass:$SRVPASS

# Imports Certificates CA Public and the signed Certificated
keytool -keystore kafka.client.keystore.jks -alias CARoot -import -file ca-cert -storepass $CLIPASS -keypass $CLIPASS -noprompt

keytool -keystore kafka.client.keystore.jks -import -file client-cert-signed -alias my-local-pc -storepass $CLIPASS -keypass $CLIPASS -noprompt
```

2. Create the client-ssl-auth.properties file
```
security.protocol=SSL
# This was created at Section Setup Client (SSL): 
ssl.truststore.location=kafka.client.truststore.jks
ssl.truststore.password=clientpass
ssl.keystore.location=kafka.client.keystore.jks
ssl.keystore.password=clientpass
ssl.key.password=clientpass
```

3. Run the producer and consummer with client-ssl-auth.properties configuration
```bash
# Create Topic
kafka-topics.sh --zookeeper <zookeeper-dns> --create --topic kafka-security-topic --replication-factor 1 --partitions 2

# Producer
kafka-console-producer.sh --broker-list <broker-dns>:9093 --topic kafka-security-topic --producer.config client-ssl-auth.properties

# Consumer
kafka-console-consumer.sh --bootstrap-server <broker-dns>:9093 --topic kafka-security-topic --consumer.config client-ssl-auth.properties
```