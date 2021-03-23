#!/bin/bash

set -x
echo "#########################################################################################"
echo "#                           Downloading Packages                                        #"
echo "#########################################################################################"

# Packages
apt-get update && \
      apt-get -y install wget ca-certificates zip net-tools vim nano tar netcat

# Java Open JDK 8
apt-get -y install openjdk-8-jdk
java -version

# Disable RAM Swap - can set to 0 on certain Linux distro
sysctl vm.swappiness=1
echo 'vm.swappiness=1' | tee --append /etc/sysctl.conf

# Download Kafka
wget --quiet https://downloads.apache.org/kafka/2.7.0/kafka_2.12-2.7.0.tgz
tar -xzf kafka_2.12-2.7.0.tgz
rm kafka_2.12-2.7.0.tgz
mv kafka_2.12-2.7.0/ kafka
cd kafka/

# Configuring HOSTS
HOSTS_ZOOKEEPER_ARRAY=($(echo ${ZOOKEEPER_HOSTS} | tr "," "\n"))
HOSTS_KAFKA_ARRAY=($(echo ${KAFKA_HOSTS} | tr "," "\n"))

for i in "$${!HOSTS_ZOOKEEPER_ARRAY[@]}"
do
  echo "$${HOSTS_ZOOKEEPER_ARRAY[$i]} zookeeper$i" >> /etc/hosts
done

for i in "$${!HOSTS_KAFKA_ARRAY[@]}"
do
  echo "$${HOSTS_KAFKA_ARRAY[$i]} kafka$i" >> /etc/hosts
done

# Configuring ZookeeperService
echo ${ZOOKEEPER_SERVICE} | base64 --decode > /etc/init.d/zookeeper
chmod +x /etc/init.d/zookeeper
chown root:root /etc/init.d/zookeeper
update-rc.d zookeeper defaults
systemctl enable zookeeper

# Configuring Zookeeper
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
mkdir -p /data/zookeeper
chown -R ubuntu:ubuntu /data/
rm -rf /kafka/config/zookeeper.properties
echo ${ZOOKEEPER_PROPERTIES} | base64 --decode > /kafka/config/zookeeper.properties

for i in "$${!HOSTS_ZOOKEEPER_ARRAY[@]}"
do
  if [[ "$PRIVATE_IP" == "$${HOSTS_ZOOKEEPER_ARRAY[$i]}" ]]; then
    echo "$i" > /data/zookeeper/myid
  fi
  echo "server.$i=zookeeper$i:2888:3888" >> /kafka/config/zookeeper.properties
done

service zookeeper start

sleep 10

for i in "$${!HOSTS_ZOOKEEPER_ARRAY[@]}"
do
  nc -vz "zookeeper$i" 2181
  echo "ruok" | nc "zookeeper$i" 2181 ; echo
  echo "stat" | nc "zookeeper$i" 2181 ; echo
done

cat logs/zookeeper.out

