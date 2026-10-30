#!/bin/bash
set -e

echo "Building image"

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

# # Run migrations in a one-off task from the web service's task definition,
# # which uses the image just pushed. The services restart only if it succeeds.
# echo "Running migrations"
# SERVICE=$(aws ecs describe-services --cluster "${AWS_ECS_CLUSTER}" --services "${AWS_ECS_SERVICE}" --region "${AWS_REGION}" --query 'services[0]')
# TASK_DEFINITION=$(echo "${SERVICE}" | jq -r '.taskDefinition')
# CONTAINER=$(aws ecs describe-task-definition --task-definition "${TASK_DEFINITION}" --region "${AWS_REGION}" \
# 	--query 'taskDefinition.containerDefinitions[0].name' --output text)

# # Start it where the service runs: same launch type or capacity providers,
# # and the same subnets and security groups when the service uses awsvpc.
# RUN_ARGS=()
# LAUNCH_TYPE=$(echo "${SERVICE}" | jq -r '.launchType // empty')
# CAPACITY_PROVIDERS=$(echo "${SERVICE}" | jq -c '.capacityProviderStrategy // empty | select(length > 0)')
# NETWORK=$(echo "${SERVICE}" | jq -c '.networkConfiguration // empty')
# if [ -n "${LAUNCH_TYPE}" ]; then
# 	RUN_ARGS+=(--launch-type "${LAUNCH_TYPE}")
# elif [ -n "${CAPACITY_PROVIDERS}" ]; then
# 	RUN_ARGS+=(--capacity-provider-strategy "${CAPACITY_PROVIDERS}")
# fi
# if [ -n "${NETWORK}" ]; then
# 	RUN_ARGS+=(--network-configuration "${NETWORK}")
# fi

# TASK_ARN=$(aws ecs run-task \
# 	--cluster "${AWS_ECS_CLUSTER}" \
# 	--task-definition "${TASK_DEFINITION}" \
# 	--region "${AWS_REGION}" \
# 	--started-by github-deploy-migrate \
# 	--overrides "{\"containerOverrides\":[{\"name\":\"${CONTAINER}\",\"command\":[\"bin/rails\",\"db:migrate\"]}]}" \
# 	"${RUN_ARGS[@]}" \
# 	--query 'tasks[0].taskArn' --output text)

# if [ -z "${TASK_ARN}" ] || [ "${TASK_ARN}" = "None" ]; then
# 	echo "The migration task did not start; see the run-task failures above"
# 	exit 1
# fi

# echo "Waiting for ${TASK_ARN}"
# aws ecs wait tasks-stopped --cluster "${AWS_ECS_CLUSTER}" --tasks "${TASK_ARN}" --region "${AWS_REGION}"

# EXIT_CODE=$(aws ecs describe-tasks --cluster "${AWS_ECS_CLUSTER}" --tasks "${TASK_ARN}" --region "${AWS_REGION}" \
# 	--query "tasks[0].containers[?name=='${CONTAINER}'].exitCode | [0]" --output text)
# if [ "${EXIT_CODE}" != "0" ]; then
# 	REASON=$(aws ecs describe-tasks --cluster "${AWS_ECS_CLUSTER}" --tasks "${TASK_ARN}" --region "${AWS_REGION}" \
# 		--query 'tasks[0].stoppedReason' --output text)
# 	echo "Migrations failed (exit code ${EXIT_CODE}: ${REASON}); the services were not restarted"
# 	exit 1
# fi
# echo "Migrations finished"

# echo "Restarting web"
# aws ecs update-service --cluster "${AWS_ECS_CLUSTER}" --service "${AWS_ECS_SERVICE}" --force-new-deployment --region "${AWS_REGION}"

# if [ -n "${AWS_ECS_SIDEKIQ_SERVICE}" ]; then
# 	echo "Restarting Sidekiq"
# 	aws ecs update-service --cluster "${AWS_ECS_CLUSTER}" --service "${AWS_ECS_SIDEKIQ_SERVICE}" --force-new-deployment --region "${AWS_REGION}"
# fi
