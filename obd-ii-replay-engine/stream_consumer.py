import json
import base64
import time
import boto3

kinesis = boto3.client(
    "kinesis",
    region_name="us-east-1",
    endpoint_url="http://localhost:4566",
    aws_access_key_id="test",
    aws_secret_access_key="test",
)

stream_name = "dev-obd-ii-telemetry"

# 1. Fetch shard ID
response = kinesis.describe_stream(StreamName=stream_name)
shard_id = response["StreamDescription"]["Shards"][0]["ShardId"]

# 2. Get Shard Iterator from the beginning of retention
iterator_response = kinesis.get_shard_iterator(
    StreamName=stream_name,
    ShardId=shard_id,
    ShardIteratorType="TRIM_HORIZON"
)
shard_iterator = iterator_response["ShardIterator"]

print(f"Listening for records on {stream_name} ({shard_id})...")

# 3. Continuous poll loop
while shard_iterator:
    records_response = kinesis.get_records(ShardIterator=shard_iterator, Limit=10)
    records = records_response.get("Records", [])
    
    for r in records:
        partition_key = r.get("PartitionKey")
        # r["Data"] is already bytes
        raw_data = r["Data"].decode("utf-8")
        print(f"[RECORD] Key={partition_key} -> {raw_data}")
        
    shard_iterator = records_response.get("NextShardIterator")
    time.sleep(1)