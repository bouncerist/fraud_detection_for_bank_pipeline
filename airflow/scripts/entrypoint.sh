#!/usr/bin/env bash

airflow db init
airflow users create \
       --username "${_AIRFLOW_WWW_USER_USERNAME="admin"}" \
       --firstname "${_AIRFLOW_WWW_USER_FIRSTNAME="Airflow"}" \
       --lastname "${_AIRFLOW_WWW_USER_LASTNAME="Admin"}" \
       --email "${_AIRFLOW_WWW_USER_EMAIL="airflowadmin@example.com"}" \
       --role "${_AIRFLOW_WWW_USER_ROLE="Admin"}" \
       --password "${_AIRFLOW_WWW_USER_PASSWORD}" || true

airflow connections add 'trino_conn' \
    --conn-type 'trino' \
    --conn-host 'trino-coordinator' \
    --conn-login 'user' \
    --conn-port '18080' || echo "Connection trino_conn already exists"

airflow connections add 'dwh_conn' \
    --conn-type 'postgres' \
    --conn-host 'dwh' \
    --conn-schema 'dwh' \
    --conn-login 'admin' \
    --conn-password 'greenplum' \
    --conn-port '5432' || echo "Connection dwh_conn' already exists"