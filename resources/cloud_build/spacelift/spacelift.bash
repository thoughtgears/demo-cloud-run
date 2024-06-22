#!/bin/bash
echo "Running /app/main.py with arguments:"
echo "--url=${SPACELIFT_URL} --key-id=${SPACELIFT_KEY_ID} --api-key=${SPACELIFT_API_KEY} --stack-id=${SPACELIFT_STACK_ID}"

python /app/main.py --url="${SPACELIFT_URL}" --key-id="${SPACELIFT_KEY_ID}" --api-key="${SPACELIFT_API_KEY}" --stack-id="${SPACELIFT_STACK_ID}"