act -j plan -W .github/workflows/deploy-aws.yml     -s AWS_ACCESS_KEY_ID=test     -s AWS_SECRET_ACCESS_KEY=test     -s AWS_DEFAULT_REGION=us-east-1     -s AWS_ENDPOINT_URL=http://host.docker.internal:4566     -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest    --input environment=dev     --input action=plan --container-options "-v $(pwd)/terraform/terraform.tfvars:/tmp/terraform.tfvars"

act -j apply -W .github/workflows/deploy-aws.yml     -s AWS_ACCESS_KEY_ID=test     -s AWS_SECRET_ACCESS_KEY=test     -s AWS_DEFAULT_REGION=us-east-1     -s AWS_ENDPOINT_URL=http://host.docker.internal:4566     -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest    --input environment=dev     --input action=apply --container-options "-v $(pwd)/terraform/terraform.tfvars:/tmp/terraform.tfvars" --env TF_LOG=ERROR

act -j build_and_push -W .github/workflows/deploy-docker-to-floci.yml     -s AWS_ACCESS_KEY_ID=test     -s AWS_SECRET_ACCESS_KEY=test     -s AWS_DEFAULT_REGION=us-east-1     -s AWS_ENDPOINT_URL=http://host.docker.internal:4566     -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest    --input environment=dev

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1


act -j apply -W .github/workflows/deploy-aws.yml     -s AWS_ACCESS_KEY_ID=test     -s AWS_SECRET_ACCESS_KEY=test     -s AWS_DEFAULT_REGION=us-east-1     -s AWS_ENDPOINT_URL=http://host.docker.internal:4566     -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest    --input environment=dev     --input action=apply --use-gitignore=false --env TF_LOG=ERROR

act -j build_and_push -W .github/workflows/deploy-docker-to-floci.yml     -s AWS_ACCESS_KEY_ID=test     -s AWS_SECRET_ACCESS_KEY=test     -s AWS_DEFAULT_REGION=us-east-1     -s AWS_ENDPOINT_URL=http://host.docker.internal:4566     -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest    --input environment=dev

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

ITERATOR=$(aws kinesis get-shard-iterator \
  --stream-name dev-obd-ii-telemetry \
  --shard-id shardId-000000000000 \
  --shard-iterator-type TRIM_HORIZON \
  --region us-east-1 \
  --endpoint-url http://localhost:4566 \
  --query "ShardIterator" \
  --output text)


aws kinesis get-records \
  --shard-iterator "$ITERATOR" \
  --region us-east-1 \
  --endpoint-url http://localhost:4566

