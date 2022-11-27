#!/bin/bash
set -e
STACKNAME=$(npx @cdk-turnkey/stackname@1.2.0 --suffix app)
echo "STACKNAME: ${STACKNAME}"
mkdir -p deploy
cp *.json deploy/
for k in BucketName PublicSecureBucketName PublicInsecureBucketName
do
  BUCKET_NAME=$(aws cloudformation describe-stacks \
    --stack-name ${STACKNAME} | \
    jq '.Stacks[0].Outputs | map(select(.OutputKey == "${k}"))[0].OutputValue' | \
    tr -d \")
  echo "BUCKET_NAME: ${BUCKET_NAME}"
  aws s3 sync \
    --content-type "application/json" \
    --delete \
    deploy/ \
    s3://${BUCKET_NAME}
done