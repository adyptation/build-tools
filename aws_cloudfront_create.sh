#!/bin/sh

if [ "x$BUCKET" = "x" ]; then
    echo "No bucket name provided."
    exit -1
fi

echo "CloudFront setup for $BUCKET"

sed -e "s/{{BUCKET}}/$BUCKET/g" aws-cloudfront-create.json > cloudfront.json

aws cloudfront create-distribution --distribution-config file://cloudfront.json > cloudfront.out 2>&1
r=$?

echo "result \$r: $r"
grep 'Already exists' cloudfront.out > /dev/null

if [[ $? -eq 0 && $r -eq 254 ]]; then
    aws cloudfront list-distributions | jq ".DistributionList.Items[] | select (.Origins.Items[].Id | contains(\"$BUCKET\")) | .DomainName" | sed 's/"//g' > url.out
    echo "Distribution already exists ($(cat url.out)). Continuing..."
    exit 0
fi

jq .Distribution.DomainName cloudfront.out | sed 's/\"//g' > url.out

echo "Exiting ($(cat url.out))."
exit $r