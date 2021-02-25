#!/bin/bash

#
# This is designed to run in the CircleCI environment and expects CIRCLE_* environment
# variables to be present
#
function beginswith() { case $2 in "$1"*) true;; *) false;; esac; }
function checkresult() { if [ $? = 0 ]; then echo TRUE; else echo FALSE; fi; }

function tag_pr() {
    tag_prefix="pr-"

    # Grab our PR number if provided
    if [ ! -z $CIRCLE_PULL_REQUEST ]; then
        # CIRCLE_PULL_REQUEST provides the full URL to the PR at Github
        pr=$(echo $CIRCLE_PULL_REQUEST | awk -F/ '{ print $7 }')
    else
        # We can't increment a non-PR build.
        echo "Non PR Build. No action."
        exit 0
    fi
    # get latest tag
    t=$(git describe --tags `git rev-list --tags --max-count=1`)

    # The (>&2 ...) redirects to stderr since we capture stdout in the script later
    #(>&2 echo "tag_pr t: $t")
    #(>&2 echo "tar_pr pr: $pr")
    #(>&2 echo "tar_pr prefix: $tag_prefix")

    if [[ $t == $tag_prefix* ]]; then
        # We already have a tag for this PR, so we increment
        num=$(echo $t | sed 's/.*\([0-9][0-9]*\)$/\1/')
        num=$((num+1))
        new="pr-$pr-$num"
    else
        new="pr-$pr-1"
    fi

    echo $new
}

function tag_release() {
    # get current release version
    if [ -f package.json ]; then
        t=$(jq -r .version package.json)
    else
        t="0.1.0" # Update to match other project needs.
    fi

    if [ ! -z $CIRCLE_BUILD_NUM ]; then
        new="$(./semver get major $t).$(./semver get minor $t).$CIRCLE_BUILD_NUM"
    else 
        # get commit logs and determine how to bump the version
        # supports #major, #minor, #patch (anything else will be 'minor')
        case "$log" in
            *#major* ) new=$(./semver bump major $t);;
            *#minor* ) new=$(./semver bump minor $t);;
            * ) new=$(./semver bump patch $t);;
        esac
    fi 
    # For our JavaScript/React projects we want to increment the version
    # in the package.json and then commit the new version for the final build.
    if [ -f package.json ]; then
        (>&2 echo "Updating package.json")
        jq '.version = "'"$new"'"' package.json > p2.json
        mv p2.json package.json

        git add package.json
        # The (>&2 ...) redirects to stderr since we capture stdout in the script later
        (>&2 git commit -m "Version bump to $new. [skip ci]")
        (>&2 git push origin $branch)

    fi

    (>&2 echo "tag_release new: $new")
    echo $new
}

release=0

# get current branch
branch=$(git rev-parse --abbrev-ref HEAD)

ssh-keyscan github.com >> ~/.ssh/known_hosts
git config user.email "admin@adyptation.com"
git config user.name "CircleCI Builder"

# Make sure we are fully up to date with any recent tags/commits during build.
git checkout $branch
git pull origin $branch

# get current commit hash for tag
commit=$(git rev-parse HEAD)

# Download semver
if [ ! -f "semver" ]; then
    curl -o semver -s https://raw.githubusercontent.com/fsaintjacques/semver-tool/master/src/semver
    chmod +x semver
fi

if [ ! -d $HOME/.ssh ]; then
    mkdir $HOME/.ssh
fi

if [ ! -z $CIRCLE_PULL_REQUEST ]; then # Found Circle PR
    new="unknown"
    # We're working with a PR
    if [ $branch == "master" ]; then
        git checkout $branch
        new=$(tag_release)
        release=1
    else
        new=$(tag_pr)
    fi

else
    # If no PR, are we on master or main?
    if [ $branch == "master" -o $branch == "main" ]; then
        new=$(tag_release)
        release=1
    else
        # This was a standard commit without a PR. Just exit. No tag.
        echo "Regular commit. Not tagging for build."
        exit 0
    fi
fi

echo "new tag: $new"
if [ $release -ne 0 ]; then
    # Production release.
    git tag -a -m "Release $new" $new
else
    git tag $new
fi

git remote -v
git push origin --tags