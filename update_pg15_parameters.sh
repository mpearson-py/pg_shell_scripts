
##--------------------------------------------------------------------------------------------------------------##
## Name:        update_pg_parameters.sh
## Purpose:     Simple BASH script that will update the PostgreSQL parameters for a given range of parameters
## Date:        22-Jul-2023
## Copyright:   Pythian Ltd
## Author:      Matt Pearson
##--------------------------------------------------------------------------------------------------------------##

## Variables

PG_CONN_STR=" -d postgres -U postgres"


## List of PostgreSQL parameters

declare -A PG_PARAMS_DICT=(["log_autovacuum_min_duration"]='0'

["auto_explain.log_min_duration"]='100'
["deadlock_timeout"]='100'
["log_checkpoints"]='on'
["log_connections"]='on'
["log_destination"]='stderr'
["log_disconnections"]='on'
["log_duration"]='off'
["log_error_verbosity"]='verbose'
["log_filename"]='postgresql_%Y-%m-%d.log'
["logging_collector"]='on'
["log_hostname"]='on'
["log_line_prefix"]=' %m[%p]: u=[%u] db=[%d] app=[%a] c=[%h] s=[%c:%l] tx=[%v:%x] '
["log_lock_waits"]='on'
["log_statement"]='mod'
["log_temp_files"]='0'

## Format the SQL List from the Associated Array (dictionary)

unset PG_PARAM_LIST
PG_PARAM_LIST="("

for PG_PARAM in "${!PG_PARAMS_DICT[@]}";
do
        let "x = x + 1"

        if [[ ${x} -eq 1 ]]; then
                PG_PARAM_LIST="('${PG_PARAM}"
        else
                PG_PARAM_LIST="${PG_PARAM_LIST}','${PG_PARAM}"
        fi

done

PG_PARAM_LIST="${PG_PARAM_LIST}')"

echo "PG_PARAM_LIST: ${PG_PARAM_LIST}"

## Check SQL settings

SQL_STMT="SELECT  name,
                  setting,
                  category,
                  short_desc
          FROM    pg_settings
          WHERE   name IN ${PG_PARAM_LIST}
          ORDER BY name;"

## Get parameters before change:

echo -e "${SQL_STMT}" | psql ${PG_CONN_STR}

## Change the parameters

for PG_PARAM in "${!PG_PARAMS_DICT[@]}";
do
        echo "Parameter: ${PG_PARAM} Value: ${PG_PARAMS_DICT[$PG_PARAM]}"
        SQL_UPDATE_PARAM="ALTER SYSTEM SET ${PG_PARAM} = '${PG_PARAMS_DICT[$PG_PARAM]}';"
        echo -e "${SQL_UPDATE_PARAM}" | psql $PG_CONN_STR
done

## Reload the parameters

SQL_RELOAD="SELECT pg_reload_conf();"

echo -e "${SQL_RELOAD}" | psql $PG_CONN_STR

## Get parameters after change:

echo -e "${SQL_STMT}" | psql ${PG_CONN_STR}
