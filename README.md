act -j plan -W .github/workflows/deploy-aws.yml     -s AWS_ACCESS_KEY_ID=test     -s AWS_SECRET_ACCESS_KEY=test     -s AWS_DEFAULT_REGION=us-east-1     -s AWS_ENDPOINT_URL=http://host.docker.internal:4566     -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest    --input environment=dev     --input action=plan --use-gitignore=false

