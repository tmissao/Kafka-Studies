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

# Download Kafka
wget --quiet https://downloads.apache.org/kafka/2.7.0/kafka_2.12-2.7.0.tgz
tar -xzf kafka_2.12-2.7.0.tgz
rm kafka_2.12-2.7.0.tgz
mv kafka_2.12-2.7.0/ kafka
cd kafka/

# Helper Function
function join_by { local d=$1; shift; local f=$1; shift; printf %s "$f" "$${@/#/$d}"; }

# Configuring HOSTS
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

# Kafka Properties
rm config/server.properties

echo ${KAFKA_PROPERTIES} | base64 --decode > /kafka/config/server.properties

for i in "$${!HOSTS_KAFKA_ARRAY[@]}"
do
  if [[ "$PRIVATE_IP" == "$${HOSTS_KAFKA_ARRAY[$i]}" ]]; then
    echo "broker.id=$i" >> /kafka/config/server.properties
    echo "advertised.listeners=PLAINTEXT://$${DNS_KAFKA[$i]}:9092" >> /kafka/config/server.properties
  fi
done

echo "$ZOOKEEPER_ADDRESS"
ZOOKEEPERS=$(join_by , "$${ZOOKEEPER_ADDRESS[@]}")
echo "$ZOOKEEPERS"
echo "zookeeper.connect=$ZOOKEEPERS/kafka" >> /kafka/config/server.properties

# Kafka Starting Services

sleep 20 # Waiting Zookeeper Services

service kafka start

sleep 10 # Waiting Kafka Services

nc -vz localhost 9092

cat /kafka/logs/server.log

# It is necessary reboot to load file limits configs
reboot