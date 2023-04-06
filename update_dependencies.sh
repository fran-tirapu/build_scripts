#!/bin/bash

# Script to update poetry dependencies and create a PULL REQUEST in github

# Positional args are mandatory:
#     -u| --github-url        :   github url to your repo
#     -q|--qa-tasks-array     :   qa tasks to complete description separated by |

# To assign PR, GH_DEV_LOGINS environment var is mandatory

# If you need github.com auth, just include it in url: "https://GH_USER:GH_TOKEN@github.com/<user>/<repo>/<repo.git>


POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -u|--github-url)
      GH_URL="$2"
      shift # past argument
      shift # past value
      ;;
    -q|--qa-tasks-array)
      QA_TASKS="$2"
      shift # past argument
      shift # past value
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

IFS='|' read -r -a QA_TASKS_LIST <<< "$QA_TASKS"

echo "GH_URL  = ${GH_URL}"
echo "QA_TASKS_LIST     = ${QA_TASKS_LIST[@]}"



set -e
# poetry update --no-interaction --no-ansi > poetry-update.log

BRANCH=dependency-update-$(date +%F)
DESCRIPTION='```
'$(cat poetry-update.log | tail -n +6)'
```

# QA
'

for task in "${QA_TASKS_LIST[@]}"
do
   DESCRIPTION=$DESCRIPTION":black_square_button: - "$task'
'

done


echo "$DESCRIPTION"

IFS=' ' read -r -a DEVELOPERS_LIST <<< "$GH_DEV_LOGINS"
DEVELOPERS_COUNT=${#DEVELOPERS_LIST[@]}
CURRENT_WEEK=$(date +%U)
DEVELOPER_LOGIN=${DEVELOPERS_LIST[$(expr $CURRENT_WEEK % $DEVELOPERS_COUNT)]}

echo "PR will be assigned to $DEVELOPER_LOGIN"


git checkout -b $BRANCH
git commit -m 'update dependency versions' .
git remote set-url origin "$GH_URL"
git push --set-upstream origin $BRANCH
gh pr create --title "Update dependencies $(date +%F)" \
  --body "$DESCRIPTION" --base master --head "${BRANCH}" --assignee $DEVELOPER_LOGIN

