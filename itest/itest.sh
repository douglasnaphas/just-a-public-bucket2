#!/bin/bash
set -e

CONTENT_OBJECT_NAME=content.json

# Get non-public bucket's name
STACKNAME=$(npx @cdk-turnkey/stackname@1.2.0 --suffix app)
BUCKET_NAME=$(aws cloudformation describe-stacks \
  --stack-name ${STACKNAME} | \
  jq '.Stacks[0].Outputs | map(select(.OutputKey == "BucketName"))[0].OutputValue' | \
  tr -d \")

# Confirm content is right
CONTENT_DATA="$(aws s3 cp s3://${BUCKET_NAME}/${CONTENT_OBJECT_NAME} - | \
  jq '.Data' | \
  tr -d \")"
EXPECTED_DATA="Something"
if [[ "${CONTENT_DATA}" != "${EXPECTED_DATA}" ]]
then
  echo "Integration test failed. Expected content data:"
  echo "${EXPECTED_DATA}"
  echo "Got:"
  echo "${CONTENT_DATA}"
  exit 2
fi

# Get bucket's domain name
BUCKET_DOMAIN=$(aws cloudformation describe-stacks \
  --stack-name ${STACKNAME} | \
  jq '.Stacks[0].Outputs | map(select(.OutputKey == "BucketDomainName"))[0].OutputValue' | \
  tr -d \")

# Confirm bucket's HTTPS URL doesn't work
PRIVATE_STATUS=$( \
  curl --head --silent https://${BUCKET_DOMAIN}/${CONTENT_OBJECT_NAME} | \
  awk 'NR == 1 {print $2}'
)
EXPECTED_PRIVATE_STATUS="403"
if [[ "${PRIVATE_STATUS}" != "${EXPECTED_PRIVATE_STATUS}" ]]
then
  echo "Integration test failed. Expected status from getting an object by URL in a private bucket:"
  echo "${EXPECTED_PRIVATE_STATUS}"
  echo "Got:"
  echo "${PRIVATE_STATUS}"
  exit 2
fi

# Public bucket with nothing blocking HTTP access, public insecure bucket (PIB)
# Get PIB's name

# Confirm PIB's content is right

# Get PIB's content URL

# Confirm PIB's HTTPS URL does work

# Confirm PIB's HTTPS URL does work

# Public bucket with IAM policy set to deny HTTP, Public Secure Bucket (PSB)
# Get PSB's name
