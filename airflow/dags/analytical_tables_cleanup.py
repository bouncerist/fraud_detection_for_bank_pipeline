from airflow import DAG
from airflow.providers.postgres.operators.postgres import PostgresOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'Gazetdinov Insaf',
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
    'start_date': datetime(2025, 11, 18),
}

with DAG(
        'analytical_data_retention_cleanup',
        default_args=default_args,
        description='Очистка старых данных из аналитических таблиц',
        schedule_interval=timedelta(days=90),
        catchup=False,
        tags=['analytics', 'cleanup']
) as dag:

    cleanup_analytical_tables = PostgresOperator(
        task_id='cleanup_analytical_tables',
        postgres_conn_id='dwh_conn',
        sql="""
        DELETE FROM analysis.daily_fraud_summary 
        WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '90 days' + INTERVAL '3' HOUR;
        
        DELETE FROM analysis.card_type_fraud_effectiveness 
        WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '90 days' + INTERVAL '3' HOUR;
        """
    )

    cleanup_analytical_tables