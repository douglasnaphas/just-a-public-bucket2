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

# Confirm content is right
correct_content () {
  local bucket=$1
  local content_data="$(aws s3 cp s3://${bucket}/${CONTENT_OBJECT_NAME} - | \
    jq '.Data' | \
    tr -d \")"
  local EXPECTED_DATA="Something"
  if [[ "${content_data}" != "${EXPECTED_DATA}" ]]
  then
    return 1
  fi
  return 0
}
if [[ ! correct_content ${BUCKET_NAME} ]]
then
  echo "Integration test failed. Expected ${BUCKET_NAME} content data:"
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
  exit 3
fi

block_exists () {
  local bucket=$1
  NO_BLOCK_EXISTS="no-block-exists"
  local block_status=$(aws s3api get-public-access-block --bucket ${bucket} &> /dev/null || echo ${NO_BLOCK_EXISTS})
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

# Fail if there's a public access block on PIB
if block_exists ${PIB_NAME}
then
  echo "public access block exists on ${PIB_NAME}"
  echo "${PIB_NAME} needs to be a public bucket, failing"
  exit 3
fi

# Confirm PIB's content is right
if [[ ! correct_content ${PIB_NAME} ]]
then
  echo "Integration test failed. Expected ${PIB_NAME} content data:"
  echo "${EXPECTED_DATA}"
  echo "Got:"
  echo "${CONTENT_DATA}"
  exit 4
fi

# Get PIB's domain name

# Confirm PIB's HTTPS content URL does work

# Confirm PIB's HTTPS content URL does work

# Public bucket with IAM policy set to deny HTTP, Public Secure Bucket (PSB)
# Get PSB's name

# Fail if there's a public access block on PSB

# Confirm PSB's content is right

# Get PSB's domain name

# Confirm PSB's HTTPS content URL does work

# Confirm PSB's HTTP content URL does NOT work
