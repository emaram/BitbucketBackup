#! /bin/bash

# To be called with:
#   bash parserepository.sh "<project_dir>" "<repository_line> <backup_type>" 

BACKUP_DIR=$1
PROJECT_DIR=$2
REPOSITORY_LINE=$3
BACKUP_TYPE=$4

BITBUCKET_CREDENTIALS=$(base64 --decode -i credentials.info)
BITBUCKET_API="https://api.bitbucket.org/2.0"

repo_name=$(echo "$REPOSITORY_LINE" | cut -d'|' -f1)
repo_url=$(echo "$REPOSITORY_LINE" | cut -d'|' -f2)
repo_api=$(echo "$REPOSITORY_LINE" | cut -d'|' -f3)

REPOSITORY_DIR="${PROJECT_DIR}/${repo_name}"
REPOSITORY_URL=${repo_url/bitbucket/$BITBUCKET_CREDENTIALS@bitbucket}.git
REPOSITORY_API=${repo_api}

# Receives a date in string format (e.g. "2024-04-05T13:27:11+00:00")
#  and calculates the differences since the current date (in number of days)
get_time_difference(){
    date_string=$1
    echo "Date string is $date_string"
    extracted_date=${date_string%%T*}
    current_date=$(date +%Y-%m-%d)

    time_difference=$(( $(gdate -d "$current_date" +%s) - $(gdate -d "$extracted_date" +%s) ))
    days_difference=$(( time_difference / (60 * 60 * 24) ))

    echo $days_difference
}

must_clone=1

# Only for delta backup
if [[ $BACKUP_TYPE = "delta" ]];
then
    echo " >>> Delta backup requested: Getting last activity for [${repo_name}] ..."
    if command -v gdate >/dev/null 2>&1; then
        response=$(curl -u $BITBUCKET_CREDENTIALS "${REPOSITORY_API}/pullrequests")
        last_pull_request=$(echo $response | jq -r '.values[0] | .updated_on')

        must_clone=0

        # If last_pull_request is NOT null
        if [[ -n $last_pull_request ]]; then
            days_difference=$(get_time_difference "${last_pull_request}")
            if [[ 7 -gt $days_difference ]]; then
                must_clone=1
            else
                response=$(curl -u $BITBUCKET_CREDENTIALS "${REPOSITORY_API}/commits")
                last_commit=$(echo $response | jq -r '.values[0] | .date')
                # If last_commit is not null
                if [[ -n $last_commit ]]; then
                    echo "Last commit is $last_commit"
                    days_difference=$(get_time_difference "${last_commit}")
                    if [[ 7 -gt $days_difference ]]; then
                        must_clone=1
                    fi
                fi
            fi
        fi
    else
        echo "Error: required tools. Please install coreutils."
        exit 0
    fi    
fi

if [[ $must_clone -eq 1 ]]; then
    echo " >>> Cloning [${repo_name}] ..."
    git clone --progress --mirror "${REPOSITORY_URL}" "${REPOSITORY_DIR}" &> "${BACKUP_DIR}/_logs/${repo_name}.clone.log"
fi

