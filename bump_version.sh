#!/bin/bash

#
# This is designed to run in the CircleCI environment and expects CIRCLE_* environment
# variables to be present
#

function tag_pr() {
    # Grab our PR number
    pr=$(echo $CIRCLE_PULL_REQUEST | awk -F/ '{ print $7 }')

    new="pr-$pr"
    echo $new
}

function tag_release() {
    # get latest tag
    t=$(git describe --tags `git rev-list --tags --max-count=1`)

    # if there are none, start tags at 0.0.0
    if [ -z "$t" ]
    then
        log=$(git log --pretty=oneline)
        t=0.0.0
    else
        log=$(git log $t..HEAD --pretty=oneline)
    fi

    # get commit logs and determine home to bump the version
    # supports #major, #minor, #patch (anything else will be 'minor')
    case "$log" in
        *#major* ) new=$(./semver bump major $t);;
        *#minor* ) new=$(./semver bump minor $t);;
        * ) new=$(./semver bump patch $t);;
    esac

    echo $new
}

function post() {
    # get repo name from git
    remote=$(git config --get remote.origin.url)
    repo=$(basename $remote .git)

    # POST a new ref to repo via Github API
    curl -s -X POST https://api.github.com/repos/$REPO_OWNER/$repo/git/refs \
    -H "Authorization: token $GITHUB_TOKEN" \
    -d @- << EOF
    {
    "ref": "refs/tags/$1",
    "sha": "$commit"
    }
EOF

}

# get current branch
branch=$(git rev-parse --abbrev-ref HEAD)

# get current commit hash for tag
commit=$(git rev-parse HEAD)

# Download semver
if [ ! -f "semver" ]; then
    curl -o semver -s https://raw.githubusercontent.com/fsaintjacques/semver-tool/master/src/semver
    chmod +x semver
fi

if [ ! -z $CIRCLE_PULL_REQUEST ]; then
    new="unknown"
    # We're working with a PR
    if [ $branch == "master" ]; then
        new=$(tag_release)
    else
        new=$(tag_pr)
    fi

    echo "new version: $new"
    post $new
fi