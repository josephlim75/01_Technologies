== Topic Deletion

*Topic Deletion* is a feature of Kafka that allows for deleting topics.

link:kafka-TopicDeletionManager.adoc[TopicDeletionManager] is responsible for topic deletion.

Topic deletion is controlled by link:kafka-properties.adoc#delete.topic.enable[delete.topic.enable] Kafka property that turns it on when `true`.

Start a Kafka broker with broker ID `100`.

```
$ ./bin/kafka-server-start.sh config/server.properties \
  --override delete.topic.enable=true \
  --override broker.id=100 \
  --override log.dirs=/tmp/kafka-logs-100 \
  --override port=9192
```

Create *remove-me* topic.

```
$ ./bin/kafka-topics.sh --zookeeper localhost:2181 \
  --create \
  --topic remove-me \
  --partitions 1 \
  --replication-factor 1
Created topic "remove-me".
```

Use `kafka-topics.sh --list` to list available topics.

```
$ ./bin/kafka-topics.sh --zookeeper localhost:2181 --list
__consumer_offsets
remove-me
```

Use `kafka-topics.sh --describe` to list details for `remove-me` topic.

```
$ ./bin/kafka-topics.sh --zookeeper localhost:2181 --describe --topic remove-me
Topic:remove-me	PartitionCount:1	ReplicationFactor:1	Configs:
	Topic: remove-me	Partition: 0	Leader: 100	Replicas: 100	Isr: 100
```

Note that the broker `100` is the leader for `remove-me` topic.

Stop the broker `100` and start another with broker ID `200`.

```
$ ./bin/kafka-server-start.sh config/server.properties \
  --override delete.topic.enable=true \
  --override broker.id=200 \
  --override log.dirs=/tmp/kafka-logs-200 \
  --override port=9292
```

Use `kafka-topics.sh --delete` to delete `remove-me` topic.

```
$ ./bin/kafka-topics.sh --zookeeper localhost:2181 --delete --topic remove-me
Topic remove-me is marked for deletion.
Note: This will have no impact if delete.topic.enable is not set to true.
```

List the topics.

```
$ ./bin/kafka-topics.sh --zookeeper localhost:2181 --list
__consumer_offsets
remove-me - marked for deletion
```

As you may have noticed, `kafka-topics.sh --delete` will only delete a topic if the topic's leader broker is available (and can acknowledge the removal). Since the broker 100 is down and currently unavailable the topic deletion has only been recorded in Zookeeper.

```
$ ./bin/zkCli.sh -server localhost:2181
[zk: localhost:2181(CONNECTED) 0] ls /admin/delete_topics
[remove-me]
```

As long as the leader broker `100` is not available, the topic to be deleted remains marked for deletion.

Start the broker `100`.

```
$ ./bin/kafka-server-start.sh config/server.properties \
  --override delete.topic.enable=true \
  --override broker.id=100 \
  --override log.dirs=/tmp/kafka-logs-100 \
  --override port=9192
```

With link:kafka-KafkaController.adoc#logging[kafka.controller.KafkaController] logger at `DEBUG` level, you should see the following messages in the logs:

```
DEBUG [Controller id=100] Delete topics listener fired for topics remove-me to be deleted (kafka.controller.KafkaController)
INFO [Controller id=100] Starting topic deletion for topics remove-me (kafka.controller.KafkaController)
INFO [GroupMetadataManager brokerId=100] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
DEBUG [Controller id=100] Removing replica 100 from ISR 100 for partition remove-me-0. (kafka.controller.KafkaController)
INFO [Controller id=100] Retaining last ISR 100 of partition remove-me-0 since unclean leader election is disabled (kafka.controller.KafkaController)
INFO [Controller id=100] New leader and ISR for partition remove-me-0 is {"leader":-1,"leader_epoch":1,"isr":[100]} (kafka.controller.KafkaController)
INFO [ReplicaFetcherManager on broker 100] Removed fetcher for partitions remove-me-0 (kafka.server.ReplicaFetcherManager)
INFO [ReplicaFetcherManager on broker 100] Removed fetcher for partitions  (kafka.server.ReplicaFetcherManager)
INFO [ReplicaFetcherManager on broker 100] Removed fetcher for partitions remove-me-0 (kafka.server.ReplicaFetcherManager)
INFO Log for partition remove-me-0 is renamed to /tmp/kafka-logs-100/remove-me-0.fe6d039ff884498b9d6113fb22a75264-delete and is scheduled for deletion (kafka.log.LogManager)
DEBUG [Controller id=100] Delete topic callback invoked for org.apache.kafka.common.requests.StopReplicaResponse@8c0f4f0 (kafka.controller.KafkaController)
INFO [Controller id=100] New topics: [Set()], deleted topics: [Set()], new partition replica assignment [Map()] (kafka.controller.KafkaController)
DEBUG [Controller id=100] Delete topics listener fired for topics  to be deleted (kafka.controller.KafkaController)
```

The topic is now deleted. Use Zookeeper CLI tool to confirm it.

```
$ ./bin/zkCli.sh -server localhost:2181
[zk: localhost:2181(CONNECTED) 1] ls /admin/delete_topics
[]
```
