package kafka.tutorial4;

import com.google.gson.JsonParser;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.kstream.KStream;

import java.util.Properties;

public class StreamsFilterTweets {

    private static final String BOOTSTRAP_SERVERS = "127.0.0.1:9092";
    private static final String APPLICATION_ID = "demo-kafka-streams";
    private static final String SOURCE_TOPIC = "twitter_tweets";
    private static final String SINK_TOPIC = "important_tweets";
    private static JsonParser jsonParser = new JsonParser();

    public static void main(String[] args) {
        // create properties
        Properties properties = new Properties();
        properties.setProperty(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, BOOTSTRAP_SERVERS);
        properties.setProperty(StreamsConfig.APPLICATION_ID_CONFIG, APPLICATION_ID);
        properties.setProperty(StreamsConfig.DEFAULT_KEY_SERDE_CLASS_CONFIG, Serdes.StringSerde.class.getName());
        properties.setProperty(StreamsConfig.DEFAULT_VALUE_SERDE_CLASS_CONFIG, Serdes.StringSerde.class.getName());

        // create a topology
        StreamsBuilder streamsBuilder = new StreamsBuilder();

        // input topic
        KStream<String, String> inputTopic = streamsBuilder.stream(SOURCE_TOPIC);
        KStream<String, String> filteredStream = inputTopic.filter(
                (k, jsonTweet) -> extractUserFollowersInTweet(jsonTweet) > 10000
        );
        filteredStream.to(SINK_TOPIC);

        // build the topology
        KafkaStreams kafkaStreams = new KafkaStreams(streamsBuilder.build(), properties);

        // start our streams applications
        kafkaStreams.start();

    }

    private static Integer extractUserFollowersInTweet(String tweetJson) {
        try {
            return jsonParser.parse(tweetJson)
                    .getAsJsonObject()
                    .get("user")
                    .getAsJsonObject()
                    .get("followers_count")
                    .getAsInt();
        } catch (NullPointerException e ) {
            return 0;
        }
    }
}
