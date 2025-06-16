#! /bin/sh

SECONDS=0

# Default backup type
BACKUP_TYPE="full"

# If we have parameters, there should be only one (full or delta)
if [[ "$#" -eq 1 ]]; 
then
    case "$1" in
        delta)
            BACKUP_TYPE="delta"
            ;;
        full)
            BACKUP_TYPE="full"
            ;;
        *)
            echo "Invalid call of backup.sh"
            echo "Usage:"
            echo "  bash backup.sh            or"
            echo "  bash backup.sh full       or"
            echo "  bash backup.sh delta"
            exit 0
            ;;
    esac
else
   if [[ "$#" -gt 1 ]]; then
        echo "Invalid number of parameters"
        echo "Usage:"
        echo "  bash backup.sh            or"
        echo "  bash backup.sh full       or"
        echo "  bash backup.sh delta"
        exit 0
   fi 
fi

# Bitbucket values
BITBUCKET_CREDENTIALS=$(base64 --decode -i credentials.info)
BITBUCKET_API="https://api.bitbucket.org/2.0"
BITBUCKET_SPACE=$(base64 --decode -i bitbucket_space)

# Get current year and current week - construct the backup directory name
WEEKNUM=$(date +%V)
YEAR=$(date +%Y)
BACKUP_DIR=$(pwd)"/${YEAR}-w${WEEKNUM}"

TEMP_FILE="${BACKUP_DIR}/total_repositories.txt"

# Create backup directory, if it does not already exist
if [[ ! -d "${BACKUP_DIR}" ]]; then
    echo "Creating backup directory [$BACKUP_DIR] ..."
    mkdir "${BACKUP_DIR}";
fi
# Create logs directory, if it does not already exist
if [[ ! -d "${BACKUP_DIR}/_logs" ]]; then
    echo "Creating logs directory [${BACKUP_DIR}/_logs] ..."
    mkdir "${BACKUP_DIR}/_logs";
fi


# ----------------------
# Get list of projects
# ----------------------

echo "Retrieving all Bitbucket projects ...."
# Retrieve the list of projects in JSON format
curl -u $BITBUCKET_CREDENTIALS "${BITBUCKET_API}/workspaces/${BITBUCKET_SPACE}/projects/?pagelen=100" &> "${BACKUP_DIR}/_logs/_backup.log" > $BACKUP_DIR/projects.json

# Parse JSON and creates a text with project name and repositories URL
jq -r '.values[] | .name + "|" + .links.repositories.href' $BACKUP_DIR/projects.json > $BACKUP_DIR/projects.txt

echo

# Parse the text file line by line
#i=4        # First four projects, for testing purposes
i=100       # ALL - there are not more than 100 projects

TOTAL_PROJECTS=0
TOTAL_REPOSITORIES=0


# Read project IDs from the file line by line
while IFS= read -r line; do
    # Check if line is empty (avoids empty line processing)
    if [[ -z "$line" ]]; then
        continue
    fi

    TOTAL_PROJECTS=$((TOTAL_PROJECTS + 1))
    echo "================================================================================="

    # Call parseproject.sh with project details (improved readability)
    ./parseproject.sh "$BACKUP_DIR" "$line" "$BACKUP_TYPE" "$TOTAL_PROJECTS"
    let "i=i-1"

    # Read cloned repositories from TEMP_FILE (if exists)
    if [[ -f "$TEMP_FILE" ]]; then
        repos=$(cat "$TEMP_FILE")
        echo "  Cloned repositories: $repos"
        TOTAL_REPOSITORIES=$((TOTAL_REPOSITORIES + ${repos}))
    fi

    # Check for loop termination condition
    if [[ $i -eq 0 ]]; then
        break
    fi
done < "${BACKUP_DIR}/projects.txt"  # Redirect file input to the loop

echo
echo   "Total projects:     ${TOTAL_PROJECTS}"
echo   "Total repositories: ${TOTAL_REPOSITORIES}"
duration=$SECONDS
printf 'Total duration:     %dh:%dm:%ds\n' $(($duration/3600)) $(($duration%3600/60)) $(($duration%60))
echo

