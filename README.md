# FRAUD DETECTION PIPELINE AND ANALYTICS IN DASHBOARD

## Documentation sections

-  [Additional features](#additional-features)
-  [Detailed Description](#detailed-description)

## Architecture

![Architecture](https://github.com/bouncerist/images/blob/architecture/fraud_detect_pipeline_architecture.png)

## Superset dashboards

![Superset_cards](https://github.com/bouncerist/images/blob/superset/мошенничество-по-картам-2025-11-19T08-26-20.793Z.jpg)

![Superset_countries_and_merchants](https://github.com/bouncerist/images/blob/superset/мошенничество-по-странам-и-категориям-мерчантов-2025-11-19T08-33-10.914Z.jpg)
## Data Storage
### bank_storage (OLTP, PostgreSQL): data source

### fraud-detector (OLTP, PostgreSQL): fraudulent transactions for instant action

### dwh (OLAP, Greenplum): data is being uploaded for analytical queries

#### You can familiarize yourself with sql scripts by going to the sql_scripts directory.
#### NOTE: bank_storage and fraud-detector are created by themselves, for dwh you will need to create yourself

## Fast run

```shell
docker-compose up -d
```

## Greenplum
### Create volume for DWH
```shell
docker volume create DWH_data
```
### Enter the container
```shell
docker exec -it dwh psql -U gpadmin -d template
```
### Create superuser
```shell
CREATE USER admin WITH
    LOGIN
    PASSWORD 'greenplum'
    SUPERUSER;
```
### Create database
```shell
CREATE DATABASE dwh
    WITH
    OWNER = admin
    ENCODING = 'UTF8';
```
### Run all the scripts
```shell
sql_scripts/dwh/create_tables_raw_data.sql
sql_scripts/dwh/create_tables_dds_data.sql
sql_scripts/dwh/update_rules.sql
```

## Register kafka connectors (bash)

```shell
manage_kafka_connectors/register-connectors.sh
```

## Create ksqlDB streams

```shell
docker exec ksqldb-cli ksql http://ksqldb-server:8088 -f /etc/ksql/init.sql
```

## Run the data generator via DBeaver by creating a connection to bank_storage <br />
1 is the number of clients,
2 is the number of transactions per client (multiple transactions)
```shell
SELECT * FROM generate_bank_data(1,2);
```

## Airflow

#### You can launch dags going to http://localhost:8088

## Superset

#### You can create dashboards going to http://localhost:8089

## STOP docker compose

```shell
docker-compose down -v
```

<a name="additional-features"></a>
## Additional features
### Delete source kafka connector:

```shell
./manage_kafka_connectrs/delete-source-connectors.sh
```

### Delete sink kafka connectors:

```shell
./manage_kafka_connectrs/delete-sink-connectors.sh
```

<a name="detailed-description"></a>
## Detailed description

## Kafka (CDC)
http://localhost:8080
Using the register-connectors script, we create connectors for kafka, thereby creating the CDC process

## ksqlDB (real-time calculation)
Fraud is calculated inside ksqlDB and when detected, is uploaded to the fraud-detector database.

## Airflow (Scheduler)
### http://localhost:8088
### Dags:
#### kafka_connect_health_check
Checks every 15 minutes whether kafka connectors is alive.
#### trino_load_to_dwh
Using trino, we download data from fraud-detector to DWH every day at 7 a.m. Moscow time
#### daily_card_type_effectiveness
We transform the data on bank cards and upload it to a new layer for analytics every day at 7:30 a.m. Moscow time
#### daily_fraud_summary
We transform the data by countries and merchants and upload it to a new layer for analytics
#### analytical_data_retention_cleanup
Clears tables for analytics once every 90 days

## Trino (SQL query engine)
you can learn more about the settings by going to the trino directory
```shell
cd trino
```
trino/coordinator (coordinate queries)
trino/workers (execute queries)

## Superset (BI tool)
### http://localhost:8089
Allows you to create dashboards for analysts