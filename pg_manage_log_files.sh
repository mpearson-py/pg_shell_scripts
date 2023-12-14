#!/bin/bash
##set -x
##-------------------------------------------------------------------------------------------------------------##
##   Name:        pg_manage_log_files.sh
##   Purpose:     Script to manage PostgreSQL log files
##
##   Author:      Matt Pearson
##   Version:     Date                            Changes
##
##   1.0          14th Dec 2023                   Original
##
##-------------------------------------------------------------------------------------------------------------##

## Postgres variables

## Set the local PATH for the script (in case it goes into crontab)

export PATH=$PATH:/usr/bin
export SCRIPT_NAME=$( basename $0 )
export SCRIPT_PREFIX=$( echo "${SCRIPT_NAME}" | awk -F. '{ print $1 }' )
export LOG_FILENAME=${SCRIPT_PREFIX}.log
export HOSTNAME=$( hostname -s )

## Global variables

## Functions

function fnUsage        ## Function for the Usage to run the script from the command line
{

[ $VERBOSE ] && echo -e "$SCRIPT_NAME"

cat << EOF

Usage:  $0 -a -c -d -f

        -a      Age of the files to compress (in days)
        -c      Compress the files, that are older than FILE_AGE
        -d      Log Directory, where the log files are to be compressed/removed
        -f      Log file format i.e. the search engine
        -r      Age of the files to remove (in days)
        -v      Verbose
        -E      Show Environmental variables

        Example: $0 -a 30 -c y -d /var/log/postgresql -f "postgres*log" -r 90

EOF

exit

}

## Get the INPUT from command line

while getopts d:f:c:a:r:vE OPTIONS 2>/dev/null
do
        case "$OPTIONS" in
                a)      FILE_AGE=$OPTARG ;;
                c)      COMPRESS==$OPTARG ;;
                d)      LOG_DIR=$OPTARG ;;
                f)      LOG_FORMAT=$OPTARG ;;
                r)      REMOVE_DATE=$OPTARG ;;
                v)      VERBOSE=1 ;;                 ## VERBOSE option
                E)      SHOW_ENV=1 ;;
                ?)      echo -e "Unknown option used on the command line."
                        fnUsage;;
        esac
done

##-----------------------------------------------------------------------------------------------------##
## Check Input Section
## Note: Convert capital letters to lower case to help with psql input
##-----------------------------------------------------------------------------------------------------##

## Validate Command Line Parameters

if [[ "$SHOW_ENV" -eq 1 ]]; then
        echo -e "Environmental variables: $( env | sort )"
fi

## Check the $LOG_DIR exists and user has privileges to delete/compress files

if [[ -z $LOG_DIR ]]; then
    echo -e "No log directory has been specified on the cmd line."
    fnUsage
fi

if [[ -d "$LOG_DIR" && -r "$LOG_DIR" &&  -w "$LOG_DIR" ]]; then
    echo -e "Directory: $LOG_DIR exists and user: $USER has R/W permissions on it."
else
    echo -e "Check directory: $LOG_DIR exists and user: $USER has R/W permissions on it."
    fnUsage
fi

## Check formatting

if [[ -z $LOG_FORMAT ]]; then
    echo -e "No log file format has been specified on the cmd line."
    fnUsage
fi

## Check FILE AGE for compression

if [[ -z ${FILE_AGE} ]]; then
    echo -e "No file age for the compression routine has been specified on the cmd line."
    fnUsage
fi

## Check age for FILE deletion

if [[ -z ${REMOVE_DATE} ]]; then
    echo -e "No remote_date age for the deletion routine has been specified on the cmd line."
    fnUsage
fi

## list files to delete

echo -e "Script ${SCRIPT_NAME} started at: $( date )\n" | tee -a $LOG_FILENAME
echo -e "List all files to be removed from $LOG_DIR\n" | tee -a $LOG_FILENAME

find $LOG_DIR -name "$LOG_FORMAT" -mtime +${REMOVE_DATE} -exec ls -l {} \; | tee -a $LOG_FILENAME

[ $VERBOSE ] && echo -e "Command to find and delete oldest files:  find $LOG_DIR -name \"$LOG_FORMAT\" -mtime +${REMOVE_DATE} -exec ls -l {} \;"

## List files to be compressed

echo -e "List all files to be compressed over $FILE_AGE days old from $LOG_DIR\n" | tee -a $LOG_FILENAME

find $LOG_DIR -name "$LOG_FORMAT" -mtime +${FILE_AGE} -exec ls -l {} \; | tee -a $LOG_FILENAME

echo -e "Script: ${SCRIPT_NAME} completed at: $( date )\n" | tee -a $LOG_FILENAME
