#!/bin/bash
set -e

CONTENT_OBJECT_NAME=content.json

# Get non-public bucket's name
STACKNAME=$(npx @cdk-turnkey/stackname@1.2.0 --suffix app)
cfn_output () {
  local output_key=$1
  aws cloudformation describe-stacks \
  --stack-name ${STACKNAME} | \
  jq --arg output_key $output_key '.Stacks[0].Outputs | map(select(.OutputKey == $output_key))[0].OutputValue' | \
  tr -d \"
}
BUCKET_NAME=$(cfn_output "BucketName")
echo "BUCKET_NAME: ${BUCKET_NAME}"

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
BUCKET_DOMAIN=$(cfn_output "BucketDomainName")

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

block_exists () {
  local bucket=$1
  NO_BLOCK_EXISTS="no-block-exists"
  local block_status=$(aws s3api get-public-access-block --bucket ${bucket} &> /dev/null || echo ${NO_BLOCK_EXISTS})
  echo "block_status: ${block_status}"
  echo "NO_BLOCK_EXISTS: ${NO_BLOCK_EXISTS}"
  if [[ "${block_status}" != "${NO_BLOCK_EXISTS}" ]]
  then
    return 0
  else
    return 1
  fi
}

if block_exists ${BUCKET_NAME}
then
  echo "block exists on ${BUCKET_NAME}"
else
  echo "no block exists on ${BUCKET_NAME}"
fi

# Public bucket with nothing blocking HTTP access, public insecure bucket (PIB)
# Get PIB's name
PIB_NAME_OUTPUT_KEY="PublicInsecureBucketName"
PIB_NAME=$(cfn_output "${PIB_NAME_OUTPUT_KEY}")
echo "PIB_NAME: ${PIB_NAME}"

# Fail if there's a public access block on PIB
if block_exists ${PIB_NAME}
then
  echo "block exists on ${PIB_NAME}"
else
  echo "no block exists on ${PIB_NAME}"
fi

# Confirm PIB's content is right

# Get PIB's domain name

# Confirm PIB's HTTPS content URL does work

# Confirm PIB's HTTPS content URL does work

# Public bucket with IAM policy set to deny HTTP, Public Secure Bucket (PSB)
# Get PSB's name

# Fail if there's a public access block on PSB
