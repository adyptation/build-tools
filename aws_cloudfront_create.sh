#!/bin/sh

if [ "x$BUCKET" = "x" ]; then
    echo "No bucket name provided."
    exit -1
fi

if [ "x$COMMIT_HASH" = "x" ]; then
    if [ "x$CIRCLE_TAG" = "x" -a "$CIRCLE_BRANCH" = "master" ]; then
        export COMMIT_HASH=$(git rev-parse --short $CIRCLE_BRANCH)
    else
        echo "Circle_tag: $CIRCLE_TAG"
        export COMMIT_HASH=$(git rev-parse --short tags/$CIRCLE_TAG~0)
    fi
fi

echo "CloudFront setup for $BUCKET (commit $COMMIT_HASH)"

sed -e "s/{{BUCKET}}/$BUCKET/g" aws-cloudfront-create.json | \
    sed -e "s/{{COMMIT_HASH}}/$COMMIT_HASH/g" \
    > cloudfront.json

aws cloudfront create-distribution --distribution-config file://cloudfront.json > cloudfront.out 2>&1
r=$?

echo "result aws cloudfront \$r: $r"
grep 'Already exists' cloudfront.out > /dev/null
r2=$?
echo "result2 grep \$r2: $r2"

url=""
if [ $r2 -eq 0 -a $r -eq 254 ]; then
    url=$(aws cloudfront list-distributions | jq -r ".DistributionList.Items[] | select (.Origins.Items[].Id | contains(\"$BUCKET\")) | .DomainName")
    if [ -z $url ]; then
        echo "Distribution already exists. Continuing..."
    else
        echo "Distribution already exists ($url). Continuing..."
    fi
    exit 0
fi

echo "Exiting ($(jq -r .Distribution.DomainName cloudfront.out))."
jq -r .Distribution.DomainName cloudfront.out > url.out
exit $r