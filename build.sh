#!/bin/bash
set -e

echo "Building image"
echo "$ENV" >> .env

docker build \
       --file Dockerfile-ecds \
       -t core-data-cloud \
       .

echo "Logging in to AWS"
aws ecr get-login-password --region us-east-1 |
       docker login --username AWS --password-stdin "${AWS_ECR}"
echo "Logged in successfully"

echo "Tagging image with latest"
docker tag core-data-cloud "${AWS_ECR}/core-data-cloud:latest"

echo "Pushing image"
docker push "${AWS_ECR}/core-data-cloud:latest"

# echo "Force update service"
aws ecs update-service --cluster ${AWS_ECS_CLUSTER} --service ${AWS_ECS_SERVICE} --force-new-deployment --region ${AWS_REGION}
