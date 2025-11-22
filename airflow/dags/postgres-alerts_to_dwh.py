from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.trino.hooks.trino import TrinoHook
from datetime import timedelta, datetime

default_args = {
    'owner': 'Gazetdinov Insaf',
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
    "start_date": datetime(2025, 10, 31),
}

TRINO_CONN_ID = 'trino_conn'

trino_hook = TrinoHook(trino_conn_id=TRINO_CONN_ID)

TRINO_QUERY = """
INSERT INTO dwh.public.fraud_alerts (
    alert_id,
    transaction_id, 
    client_id,
    card_id,
    amount,
    merchant_id,
    transaction_date,
    risk_score,
    risk_reasons,
    alert_level,
    status,
    created_at
)
SELECT 
    alert_id,
    transaction_id,
    client_id,
    card_id,
    amount,
    merchant_id,
    transaction_date,
    risk_score,
    risk_reasons,
    alert_level,
    status,
    created_at
FROM "fraud-detector".public.fraud_alerts
WHERE 
    created_at >= CURRENT_TIMESTAMP - INTERVAL '1' DAY  + INTERVAL '3' HOUR
    AND created_at < CURRENT_TIMESTAMP  + INTERVAL '3' HOUR
    AND status = 'new'
"""

def load_data():
    result = trino_hook.run(TRINO_QUERY)
    return result

with DAG(
        'trino_load_to_dwh',
        default_args=default_args,
        description='Ежедневная трансформация данных для аналитики',
        schedule_interval="0 7 * * *",
        catchup=False
) as dag:

    weather_transform = PythonOperator(
        task_id='load_data',
        python_callable=load_data,
    )