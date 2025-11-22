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
        'daily_fraud_summary',
        default_args=default_args,
        description='Ежедневная сводка по мошенничеству по странам и категориям мерчантов',
        schedule_interval='30 7 * * *',
        catchup=False,
        tags=['analytics', 'fraud', 'daily']
) as dag_daily_fraud:

    daily_fraud_summary_task = PostgresOperator(
        task_id='daily_fraud_summary',
        postgres_conn_id='dwh_conn',
        sql="""
        INSERT INTO analysis.daily_fraud_summary
        SELECT
            CURRENT_DATE as analysis_date,
            c.country,
            m.category as merchant_category,
            COUNT(f.alert_id) as total_alerts,
            SUM(f.amount) as total_amount,
            AVG(f.risk_score) as avg_risk_score,
            COUNT(CASE WHEN f.alert_level = 'high' THEN 1 END) as high_risk_alerts,
            COUNT(CASE WHEN f.alert_level = 'medium' THEN 1 END) as medium_risk_alerts
        FROM public.fraud_alerts f
        JOIN public.clients c ON f.client_id = c.id
        JOIN public.merchants m ON f.merchant_id = m.id
        WHERE f.transaction_date >= CURRENT_TIMESTAMP - INTERVAL '1 day' + INTERVAL '3 hours' 
          AND f.transaction_date < CURRENT_TIMESTAMP + INTERVAL '3 hours'
          AND f.status = 'new'
        GROUP BY c.country, m.category;
        """
    )

    daily_fraud_summary_task