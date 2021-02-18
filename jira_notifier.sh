#!/bin/sh

# This needs to be changed and removed. Then used as an env var during builds.
FORGE_CI_TOKEN=0WrPtH9rvJY3D2ZAXNWk

FORGE_URL=https://ef6bf299-777e-41ca-847d-ee5743bd49ce.hello.atlassian-dev.net/x0/eyJjdHgiOiJhcmk6Y2xvdWQ6amlyYTo6c2l0ZS80OGJjMDJlYy03ZDIzLTQzMWYtYmZiOC04NTE4NjM5OTBlNTYiLCJleHQiOiJhcmk6Y2xvdWQ6ZWNvc3lzdGVtOjpleHRlbnNpb24vZWY2YmYyOTktNzc3ZS00MWNhLTg0N2QtZWU1NzQzYmQ0OWNlLzRjMDEzZDFlLTMwNWEtNGRkOC04NmQ4LTMyOGFjNzBiMGEyMi9zdGF0aWMvY2ktbm90aWZpZXItd2VidHJpZ2dlci1zeW5jIn0


if [ "x$BRANCH" = "x" -o "x$URL" = "x" ]; then
    echo "Environment varibles missing. URL and BRANCH"
    exit -1
fi

ISSUE=$(echo $BRANCH | egrep -o "([A-Za-z]{1,3}-[0-9]{1,6})")

if [ "x$ISSUE" = "x" ]; then
    echo "Unable to parse issue from branch \"$BRANCH\". Exiting..."
    exit -1
fi

DATA="{ \"issue\": \"$ISSUE\", \"comment\": \"Preview available at: $URL \" }"
echo $DATA


response=$(curl -s -X POST -H "Content-Type: application/json" --data "$DATA" $FORGE_URL)

echo $response | jq .status | sed 's/^/Status: /'
echo $response | jq .body | sed 's/"//g' | sed 's/^/Response: /'
