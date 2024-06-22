#!/bin/bash
URL=${SPACELIFT_API_URL}
KEY_ID=${SPACELIFT_API_KEY_ID}
API_KEY=${SPACELIFT_API_KEY}
STACK_ID=${SPACELIFT_STACK_ID}

echo "Running /app/main.py with arguments:"
echo "--url=${URL} --key-id=${KEY_ID} --api-key=${API_KEY} --stack-id=${STACK_ID}"

python /app/main.py --url="${URL}" --key-id="${KEY_ID}" --api-key="${API_KEY}" --stack-id="${STACK_ID}"