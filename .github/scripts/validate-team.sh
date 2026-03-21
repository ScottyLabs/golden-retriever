#!/bin/bash
set -e

PR_AUTHOR=$1
TEAM_FILE=$2

if [[ "$TEAM_FILE" != *.json ]]; then
  echo "Skipping non-JSON file: $TEAM_FILE"
  exit 0
fi

IS_MAINTAINER=$(python3 -c "
import json, sys
team = json.load(open('$TEAM_FILE'))
print('yes' if '$PR_AUTHOR' in team.get('maintainers', []) else 'no')
")

if [[ "$IS_MAINTAINER" != "yes" ]]; then
  echo "::error file=$TEAM_FILE::Team creator $PR_AUTHOR must be listed as a maintainer in $TEAM_FILE"
  exit 1
fi

echo "Team creator membership validated for $PR_AUTHOR"
