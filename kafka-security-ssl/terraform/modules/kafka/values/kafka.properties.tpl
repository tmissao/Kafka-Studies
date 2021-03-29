############################# Log Basics #############################

# A comma seperated list of directories under which to store log files
log.dirs=/data/kafka

# The default number of log partitions per topic. More partitions allow greater
# parallelism for consumption, but this will also result in more files across
# the brokers.
num.partitions=3
# we will have 3 brokers so the default replication factor should be 2 or 3
default.replication.factor=1
# number of ISR to have in order to minimize data loss
min.insync.replicas=1

offsets.topic.replication.factor=1

############################# Log Retention Policy #############################

# The minimum age of a log file to be eligible for deletion due to age
# this will delete data after a week
log.retention.hours=168

# The maximum size of a log segment file. When this size is reached a new log segment will be created.
log.segment.bytes=1073741824

# The interval at which log segments are checked to see if they can be deleted according
# to the retention policies
log.retention.check.interval.ms=300000

############################# Zookeeper #############################

# Timeout in ms for connecting to zookeeper
zookeeper.connection.timeout.ms=6000


############################## Other ##################################
# I recommend you set this to false in production.
# We'll keep it as true for the course
auto.create.topics.enable=true

############################# Server Basics #############################

# Switch to enable topic deletion or not, default value is false
delete.topic.enable=true
ssl.client.auth=${ENABLE_SSL_AUTHENTICATION}

listeners=PLAINTEXT://0.0.0.0:9092,SSL://0.0.0.0:9093
