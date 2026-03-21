#!/bin/bash
set -e

PR_AUTHOR=$1
CONTRIBUTOR_FILE=$2

GITHUB_USERNAME=$(python3 -c "import json; print(json.load(open('$CONTRIBUTOR_FILE')).get('github_username', ''))")

if [[ -z "$GITHUB_USERNAME" ]]; then
  echo "::error file=$CONTRIBUTOR_FILE::Missing github_username field"
  exit 1
fi

if [[ "$GITHUB_USERNAME" != "$PR_AUTHOR" ]]; then
  echo "::error file=$CONTRIBUTOR_FILE::Contributor file must be submitted by $GITHUB_USERNAME themselves, not by $PR_AUTHOR"
  exit 1
fi

echo "Self-nomination validated for $GITHUB_USERNAME"
