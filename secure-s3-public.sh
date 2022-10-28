#!/bin/bash

S3CLI_PUT="aws s3api put-public-access-block --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true --bucket"

BUCKETS=$(aws s3 ls| grep serverlessdeploymentbuc | awk '{ print $3; }')

for b in $BUCKETS; do
  echo "Bucket: $b"
  $S3CLI_PUT $b
done
