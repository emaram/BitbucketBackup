#! /bin/bash

# To be called with:
#   bash parseproject.sh "<backup_dir>" "<project_line> <backup_type>" 

BACKUP_DIR=$1
PROJECT_LINE=$2
BACKUP_TYPE=$3
TOTAL_PROJECTS=$4
# echo $BACKUP_DIR $PROJECT_LINE

# Bitbucket values
BITBUCKET_CREDENTIALS=$(base64 --decode -i credentials.info)
BITBUCKET_API="https://api.bitbucket.org/2.0"

TEMP_FILE="${BACKUP_DIR}/total_repositories.txt"

PAGE_LEN=100

project_name=$(echo "$PROJECT_LINE" | cut -d'|' -f1)
repositories=$(echo "$PROJECT_LINE" | cut -d'|' -f2)

######################### 
# Backup ONLY projects related to Cristino D'Souza and Jesus Martin
# p1="Platform Long Range UAV"
# p2="Guidance Navigation and Control"
# p3="Planning & Decision-Making"
# p4="Indoor UAV"
# p5="CV Long Range UAV"
# p6="Computer Vision and Perception"
# p7="Control and ML for drones"
# p8="Swarm"

# if [[   "$project_name" != "$p1" && "$project_name" != "$p2" && "$project_name" != "$p3" && "$project_name" != "$p4" &&
#         "$project_name" != "$p5" && "$project_name" != "$p6" && "$project_name" != "$p7" && "$project_name" != "$p8" ]]; then
#     exit 0
# fi

######################### 


echo "${TOTAL_PROJECTS}) Project: [${project_name}]"


PROJECT_DIR="${BACKUP_DIR}/${project_name}"
REPOSITORIES_URL=${repositories}

# Delete directory if exists
rm -rf "${PROJECT_DIR}"

# Create project_name directory, if it does not already exist
if [ ! -d "${PROJECT_DIR}" ]; then
    echo "Creating directory ${PROJECT_DIR} ..."
    mkdir "${PROJECT_DIR}"
fi

rm -f "${PROJECT_DIR}/repositories.json"
rm -f "${PROJECT_DIR}/repositories.txt"


page=1
while : ; do

    echo "Retrieving repositories - page ${page}..."
    # Retrieve the list of repositories in JSON format
    curl -u $BITBUCKET_CREDENTIALS "${REPOSITORIES_URL}&pagelen=${PAGE_LEN}&page=${page}" &> "${BACKUP_DIR}/_logs/_project_${project_name}.log" > "${PROJECT_DIR}/repositories.json"

    # Check if there are no repositories in this project. Exit if there are no repos.
    number_of_repos=""
    number_of_repos="$(jq -r '.size' "${PROJECT_DIR}/repositories.json")"
    if [ $number_of_repos -eq 0 ]; then
        echo "0" > $TEMP_FILE
        exit 0
    fi

    # Parse JSON and appends to textfile with repo name and git clone URL
    jq -r '.values[] | .name + "|" + .links.html.href + "|" + .links.self.href' "${PROJECT_DIR}/repositories.json" >> "${PROJECT_DIR}/repositories.txt"
    current_repos=$(($page * $PAGE_LEN))

    if [[ $current_repos -gt $number_of_repos ]]; then
        break
    fi

    # If we are here, then there is a nextpage and we call it. Overwrite repositories.json
    let "page=page+1"

done

# Parse the text file line by line
cat "${PROJECT_DIR}/repositories.txt" | while read line || [[ -n $line ]];
do
    ./parserepository.sh "$BACKUP_DIR" "$PROJECT_DIR" "$line" "$BACKUP_TYPE"

done

echo ${number_of_repos} > $TEMP_FILE