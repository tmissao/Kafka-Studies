package kafka.tutorial2;

import com.google.common.collect.Lists;
import com.twitter.hbc.ClientBuilder;
import com.twitter.hbc.core.Client;
import com.twitter.hbc.core.Constants;
import com.twitter.hbc.core.Hosts;
import com.twitter.hbc.core.HttpHosts;
import com.twitter.hbc.core.endpoint.StatusesFilterEndpoint;
import com.twitter.hbc.core.processor.StringDelimitedProcessor;
import com.twitter.hbc.httpclient.auth.Authentication;
import com.twitter.hbc.httpclient.auth.OAuth1;
import org.apache.kafka.clients.producer.*;
import org.apache.kafka.common.serialization.StringSerializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.Properties;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;

public class TwitterProducer {

    private final String TWITTER_CONSUMER_KEY = "<TWITTER_API_KEY>";
    private final String TWITTER_CONSUMER_SECRET = "<TWITTER_API_SECRET>";
    private final String TWITTER_TOKEN = "<TWITTER_ACCESS_TOKEN>";
    private final String TWITTER_SECRET = "<TWITTER_SECRET_TOKEN>";
    private final List<String> TWITTER_TERMS = Lists.newArrayList("bitcoin", "soccer", "usa", "sport");


    private final String KAFKA_BOOTSTRAP_SERVERS = "127.0.0.1:9092";
    private final String KAFKA_TOPIC = "twitter_tweets";

    private Logger logger = LoggerFactory.getLogger(TwitterProducer.class.getName());

    private TwitterProducer(){}

    public static void main(String[] args) {
       new TwitterProducer().run();
    }

    private void run() {
        logger.info("Setup");
        // Create twitter client
        BlockingQueue<String> msgQueue = new LinkedBlockingQueue<String>(1000);
        Client client = createTwitterClient(msgQueue, TWITTER_TERMS);
        client.connect();

        // Create Kafka Producer
        KafkaProducer<String, String> producer = createKafkaProducer();

        // Shutdown Hook
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            logger.info("Stopping Application");
            client.stop();
            producer.close();
            logger.info("ShutDown Application done!");
        }));

        // Loop to Send Tweets to kafka
        while (!client.isDone()) {
            String msg = null;
            try {
                msg = msgQueue.poll(5, TimeUnit.SECONDS);
            } catch (InterruptedException e) {
                logger.error("Twitter Error", e);
                client.stop();
            }

            if (msg != null) {
                producer.send(new ProducerRecord<String, String>(KAFKA_TOPIC, null, msg), new Callback() {
                    @Override
                    public void onCompletion(RecordMetadata recordMetadata, Exception e) {
                        if(e != null) {
                            logger.error("Unable to send Message", e);
                        }
                    }
                });
                logger.info(msg);
            }
        }

        logger.info("End of Application");
    }

    private Client createTwitterClient(BlockingQueue<String> msgQueue, List<String> terms ){

        Hosts hosebirdHosts = new HttpHosts(Constants.STREAM_HOST);
        StatusesFilterEndpoint hosebirdEndpoint = new StatusesFilterEndpoint();
        hosebirdEndpoint.trackTerms(terms);

        // These secrets should be read from a config file
        Authentication hosebirdAuth = new OAuth1(TWITTER_CONSUMER_KEY, TWITTER_CONSUMER_SECRET, TWITTER_TOKEN, TWITTER_SECRET);

        ClientBuilder builder = new ClientBuilder()
                .name("Kafka-Client-Twitter-01")
                .hosts(hosebirdHosts)
                .authentication(hosebirdAuth)
                .endpoint(hosebirdEndpoint)
                .processor(new StringDelimitedProcessor(msgQueue));

        Client hosebirdClient = builder.build();

        return hosebirdClient;
    }

    private KafkaProducer<String, String> createKafkaProducer() {
        // Producer Properties
        Properties properties = new Properties();
        properties.setProperty(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, KAFKA_BOOTSTRAP_SERVERS);
        properties.setProperty(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        properties.setProperty(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());

        // Safe Producer
        properties.setProperty(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, "true");
        properties.setProperty(ProducerConfig.ACKS_CONFIG, "all");
        properties.setProperty(ProducerConfig.RETRIES_CONFIG, Integer.toString(Integer.MAX_VALUE));
        properties.setProperty(ProducerConfig.MAX_IN_FLIGHT_REQUESTS_PER_CONNECTION, "5");

        // High Throughput Producer
        properties.setProperty(ProducerConfig.COMPRESSION_TYPE_CONFIG, "snappy");
        properties.setProperty(ProducerConfig.LINGER_MS_CONFIG, "20");
        properties.setProperty(ProducerConfig.BATCH_SIZE_CONFIG, Integer.toString(32*1024)); // 32 KB


        // Create Producer
        KafkaProducer<String, String> producer = new KafkaProducer<String, String>(properties);
        return producer;
    }
}
