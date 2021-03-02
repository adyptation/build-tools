#!/bin/sh

if [ "x$BUCKET" = "x" ]; then
    echo "No bucket name provided."
    exit -1
fi

echo "Bucket: $BUCKET"

# Search our list of distributions for one matching our PR branch
aws cloudfront list-distributions | \
    jq ".DistributionList.Items[] | select (.Origins.Items[].Id | contains(\"$BUCKET\"))" \
    > cf-list.json

# Setup our ID for later use
ID=$(jq -r .Id cf-list.json)

if [ "x$ID" = "x" ]; then
    echo "No CloudFront Distribution found."
    exit 0
fi

aws cloudfront get-distribution-config --id $ID > cf-distribution.json

# We need the ETag in order to delete the distribution
ETAG=$(jq -r .ETag cf-distribution.json)

echo $ETAG
exit
# Set enabled to false, capture only DistributionConfig for deletion config
jq '.DistributionConfig.Enabled = false' cf-distribution.json | \
    jq .DistributionConfig > cf-disable.json

# First we have to disable the CloudFront distribution
echo "Disabling CloudFront Distribution $ID"
aws cloudfront update-distribution --id $ID --distribution-config file://cf-disable.json \
    --if-match $ETAG > cf-update.json

# We need to wait and recheck the status before deleting.
while [ 1 ]; do
    sleep 5

    STATUS=$(aws cloudfront get-distribution --id $ID | jq -r .Distribution.Status)

    if [ $STATUS = "Deployed" ]; then
        # Finally we can delete the distribution
        echo "Deleting CloudFront Distribution $ID with ETag $ETAG"
        ETAG=$(aws cloudfront get-distribution --id $ID | jq -r .ETag)
        aws cloudfront delete-distribution --id $ID --if-match $ETAG
        exit
    fi

done
