#!/bin/bash

set -x
echo "#########################################################################################"
echo "#                           Downloading Packages                                        #"
echo "#########################################################################################"

# Packages
apt-get update && \
      apt-get -y install wget ca-certificates zip net-tools vim nano tar netcat xfsprogs

# Java Open JDK 8
apt-get -y install openjdk-8-jdk
java -version

# Disable RAM Swap - can set to 0 on certain Linux distro
sysctl vm.swappiness=1
echo 'vm.swappiness=1' | tee --append /etc/sysctl.conf

# Add file limits configs - allow to open 100,000 file descriptors
echo "* hard nofile 100000
* soft nofile 100000" | tee --append /etc/security/limits.conf

KAFKA_PATH="/kafka"
SSL_PATH="/ssl"

# Download Kafka
wget --quiet https://downloads.apache.org/kafka/2.7.0/kafka_2.12-2.7.0.tgz
tar -xzf kafka_2.12-2.7.0.tgz
rm kafka_2.12-2.7.0.tgz
mv kafka_2.12-2.7.0/ kafka
cd $KAFKA_PATH

# Helper Function
function join_by { local d=$1; shift; local f=$1; shift; printf %s "$f" "$${@/#/$d}"; }

# Configuring HOSTS
PUBLIC_DNS=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
HOSTS_ZOOKEEPER_ARRAY=($(echo ${ZOOKEEPER_HOSTS} | tr "," "\n"))
HOSTS_KAFKA_ARRAY=($(echo ${KAFKA_HOSTS} | tr "," "\n"))
ZOOKEEPER_ADDRESS=()
DNS_KAFKA=()

for i in "$${!HOSTS_ZOOKEEPER_ARRAY[@]}"
do
  ZOOKEEPER_ADDRESS+=("zookeeper$i:2181")
  echo "$${HOSTS_ZOOKEEPER_ARRAY[$i]} zookeeper$i" >> /etc/hosts
done

for i in "$${!HOSTS_KAFKA_ARRAY[@]}"
do
   DNS_KAFKA+=("kafka$i")
  echo "$${HOSTS_KAFKA_ARRAY[$i]} kafka$i" >> /etc/hosts
done

# Configuring Kafka Data Disk Partition
fdisk /dev/nvme1n1
mkfs.xfs -f /dev/nvme1n1

mkdir -p /data/kafka
echo '/dev/nvme1n1 /data/kafka xfs defaults 0 0' >> /etc/fstab
mount /data/kafka
chown -R ubuntu:ubuntu /data/kafka

# Configuring KafkaService
echo ${KAFKA_SERVICE} | base64 --decode > /etc/init.d/kafka
chmod +x /etc/init.d/kafka
chown root:root /etc/init.d/kafka
update-rc.d kafka defaults
systemctl enable kafka

# Configuring SSL
SRVPASS=${CERTIFICATE_SECRET}
mkdir -p $SSL_PATH
cd $SSL_PATH

echo ${SSL_CERTIFICATE} | base64 --decode > "./ca-cert"
echo ${SSL_CERTIFICATE_PRIVATE_KEY} | base64 --decode > "./ca-key"
SERVER_KEYSTORE_PATH="kafka.server.keystore.jks"
SERVER_TRUSTSTORE_PATH="kafka.server.truststore.jks"

# Creates the Truststore file
keytool -keystore $SERVER_TRUSTSTORE_PATH -alias ca-cert -import -file ca-cert -storepass $SRVPASS -keypass $SRVPASS -noprompt
# Creates the KeyStore file
keytool -keystore $SERVER_KEYSTORE_PATH -alias kafka -validity 3650 -storepass $SRVPASS -keypass $SRVPASS -genkey -keyalg RSA -ext "SAN=dns:$PUBLIC_DNS" -dname "CN=$PUBLIC_DNS" -noprompt
# Creates Certificate Sign Request
keytool -keystore $SERVER_KEYSTORE_PATH -alias kafka -certreq -file ca-request-kafka -storepass $SRVPASS -keypass $SRVPASS
# Signs the Request
openssl x509 -req -CA ca-cert -CAkey ca-key -in ca-request-kafka -out ca-signed-kafka -days 3650 -CAcreateserial -passin pass:$SRVPASS
# Imports the CA private key into KeyStore
keytool -keystore $SERVER_KEYSTORE_PATH -alias ca-cert -import -file ca-cert -storepass $SRVPASS -keypass $SRVPASS -noprompt
# Imports the Certificate Signed into KeyStore
keytool -keystore $SERVER_KEYSTORE_PATH -alias kafka -import -file ca-signed-kafka -storepass $SRVPASS -keypass $SRVPASS -noprompt

# Kafka Properties
cd $KAFKA_PATH
SERVER_PROPERTIES_FILE_PATH="$KAFKA_PATH/config/server.properties"
rm config/server.properties

echo ${KAFKA_PROPERTIES} | base64 --decode > $SERVER_PROPERTIES_FILE_PATH

for i in "$${!HOSTS_KAFKA_ARRAY[@]}"
do
  if [[ "$PRIVATE_IP" == "$${HOSTS_KAFKA_ARRAY[$i]}" ]]; then
    echo "broker.id=$i" >> $SERVER_PROPERTIES_FILE_PATH
  fi
done

# Advertised Listeners
echo "advertised.listeners=PLAINTEXT://$PUBLIC_DNS:9092,SSL://$PUBLIC_DNS:9093" >> $SERVER_PROPERTIES_FILE_PATH

# SSL

echo "ssl.keystore.location=$SSL_PATH/$SERVER_KEYSTORE_PATH" >> $SERVER_PROPERTIES_FILE_PATH
echo "ssl.keystore.password=$SRVPASS" >> $SERVER_PROPERTIES_FILE_PATH
echo "ssl.key.password=$SRVPASS" >> $SERVER_PROPERTIES_FILE_PATH
echo "ssl.truststore.location=$SSL_PATH/$SERVER_TRUSTSTORE_PATH" >> $SERVER_PROPERTIES_FILE_PATH
echo "ssl.truststore.password=$SRVPASS" >> $SERVER_PROPERTIES_FILE_PATH

# Zookeeper
echo "$ZOOKEEPER_ADDRESS"
ZOOKEEPERS=$(join_by , "$${ZOOKEEPER_ADDRESS[@]}")
echo "$ZOOKEEPERS"
echo "zookeeper.connect=$ZOOKEEPERS/kafka" >> $SERVER_PROPERTIES_FILE_PATH

# Kafka Starting Services

sleep 20 # Waiting Zookeeper Services

service kafka start

sleep 10 # Waiting Kafka Services

nc -vz localhost 9092

cat /kafka/logs/server.log

# It is necessary reboot to load file limits configs
reboot