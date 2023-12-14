#!/bin/bash

## Global variables

export PATH=$PATH:/usr/bin
export SCRIPT_NAME=$( basename $0 )
export SCRIPT_PREFIX=$( echo "${SCRIPT_NAME}" | awk -F. '{ print $1 }' )
export LOG_FILENAME=${SCRIPT_PREFIX}.log
export HOSTNAME=$( hostname -s )

VERBOSE=1

## PG Connect variables

export HOSTNAME="127.0.0.1"
export DBNAME="db01"
export PGUSER="postgres"

export PG_CONNECT_STR=" -h $HOSTNAME -d $DBNAME -U $PGUSER"

## Setup the Error file

export ERR_FILE=/tmp/${SCRIPT_PREFIX}.err

cat /dev/null > ${ERR_FILE}

## Functions

function fnError
{

    ## Parse Error file if exists

    if [[ -s ${ERR_FILE} ]]; then
        echo -e "Error recorded in error file: $( cat $ERR_FILE )"
        exit 1
    fi

}

## Get table list

SQL_STR="SELECT  n.nspname schema_name,
                 c.relname table_name
         FROM    pg_catalog.pg_class c,
                 pg_catalog.pg_namespace n
         WHERE   n.nspname NOT IN ('pg_catalog')
         AND     c.relnamespace = n.oid
         AND     c.relkind = 'r'
         ORDER BY 1,2;"


## Get the table list (tuples only)

GET_TAB_LIST=$( echo -e "$SQL_STR" | psql $PG_CONNECT_STR -t 2>$ERR_FILE )

## Check the return code

if [ $? -ne 0 ]; then
    echo -e "SQL query: ${SQL_STR} did not return a success."
    fnError
    exit
else
    fnError
fi

[ $VERBOSE ] && echo -e "Table list: $GET_TAB_LIST\n"

echo -e "$GET_TAB_LIST" | awk -F\| '{ print $1 " " $2 }' | while read SCHEMANAME TABLENAME
do

    PG_STAT_TUPLE_QUERY="SELECT * FROM pgstattuple('${SCHEMANAME}.${TABLENAME}');"
    PG_STAT_TUPLE_RESULTS=$( echo -e "${PG_STAT_TUPLE_QUERY}" | psql $PG_CONNECT_STR -t 2>$ERR_FILE )

    [ $VERBOSE ] && echo -e "PG_STAT_TUPLE_QUERY query: ${PG_STAT_TUPLE_QUERY}\n"

    if [ $? -ne 0 ]; then
         echo -e "SQL query for pgstattuple: $PG_STAT_TUPLE_QUERY did not run successfully.\n"
         fnError
         exit
    else
         fnError
         echo -e "Stat data for table: ${SCHEMANAME}.${TABLENAME}\n${PG_STAT_TUPLE_RESULTS}\n"
    fi

done
