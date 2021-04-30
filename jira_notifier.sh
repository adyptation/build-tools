#!/bin/sh


if [ "x$FORGE_URL" = "x" ]; then
    echo "No FORGE_URL set. Exiting..."
    exit 0 # Clean exit so build doesn't break.
fi

if [ "x$BRANCH" = "x" -o "x$URL" = "x" ]; then
    echo "Environment varibles missing. URL and BRANCH"
    exit -1
fi

ISSUE=$(echo $BRANCH | egrep -o "([A-Za-z]{1,3}-[0-9]{1,6})")

if [ "x$ISSUE" = "x" ]; then
    echo "Unable to parse issue from branch \"$BRANCH\". Exiting..."
    exit 0 # Clean exit so build doesn't break.
fi

#
# I have been unable to find a way to send a URL link to Jira, only the text.
# Neither Markdown or straight HTML seem to work.
# 2021-Feb-26 -seh
#
DATA="{ \"issue\": \"$ISSUE\", \"comment\": \"Preview available at $URL\" }"
echo $DATA


response=$(curl -s -X POST -H "Content-Type: application/json" --data "$DATA" $FORGE_URL)

echo $response | jq -r .status | sed 's/^/Status: /'
echo $response | jq -r .body | sed 's/^/Response: /'
