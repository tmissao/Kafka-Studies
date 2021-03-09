#!/bin/bash

set -x
echo "#########################################################################################"
echo "#                           Downloading Packages                                        #"
echo "#########################################################################################"

# Packages
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

# set up the stable repository.
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# install docker
apt-get update
apt-get install -y docker-ce docker-compose

usermod -aG docker ubuntu
systemctl enable docker

# Helper Function
function join_by { local d=$1; shift; local f=$1; shift; printf %s "$f" "$${@/#/$d}"; }

PUBLIC_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
HOSTS_ZOOKEEPER_ARRAY=($(echo ${ZOOKEEPER_HOSTS} | tr "," "\n"))
HOSTS_KAFKA_ARRAY=($(echo ${KAFKA_HOSTS} | tr "," "\n"))
ZOOKEEPER_ADDRESS=()
KAFKA_ADDRESS=()

for i in "$${!HOSTS_ZOOKEEPER_ARRAY[@]}"
do
  ZOOKEEPER_ADDRESS+=("zookeeper$i:2181")
  echo "$${HOSTS_ZOOKEEPER_ARRAY[$i]} zookeeper$i" >> /etc/hosts
done

for i in "$${!HOSTS_KAFKA_ARRAY[@]}"
do
  KAFKA_ADDRESS+=("kafka$i:9092")
  echo "$${HOSTS_KAFKA_ARRAY[$i]} kafka$i" >> /etc/hosts
done

ZOOKEEPERS=$(join_by , "$${ZOOKEEPER_ADDRESS[@]}")
KAFKA=$(join_by , "$${KAFKA_ADDRESS[@]}")

# ZooNavigator
echo ${ZOO_NAVIGATOR_DEPLOYMENT} | base64 --decode > zoonavigator-docker-compose.yml
docker-compose -f zoonavigator-docker-compose.yml up -d

# KafkaManager
echo ${KAFKA_MANAGER_DEPLOYMENT} | base64 --decode > kafka-manager-docker-compose.yml
sed -i "s/__{ZOOKEEPER_DNS}__/$ZOOKEEPERS/" kafka-manager-docker-compose.yml
docker-compose -f kafka-manager-docker-compose.yml up -d

# KafkaTopicUi
echo ${KAFKA_TOPICS_UI_DEPLOYMENT} | base64 --decode > kafka-topics-ui-docker-compose.yml
sed -i "s/__{ZOOKEEPER_DNS}__/$ZOOKEEPERS/" kafka-topics-ui-docker-compose.yml
sed -i "s/__{KAFKA_DNS}__/$KAFKA/" kafka-topics-ui-docker-compose.yml
sed -i "s/__{HOST_PUBLIC_IP}__/$PUBLIC_IP/" kafka-topics-ui-docker-compose.yml
docker-compose -f kafka-topics-ui-docker-compose.yml up -d