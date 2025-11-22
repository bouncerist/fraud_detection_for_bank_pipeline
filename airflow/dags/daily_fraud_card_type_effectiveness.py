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
    'daily_card_type_effectiveness',
    default_args=default_args,
    description='Эффективность обнаружения мошенничества по типам карт',
    schedule_interval='30 7 * * *',
    catchup=False,
    tags=['analytics', 'cards', 'daily']
) as dag_card_effectiveness:

    card_type_effectiveness_task = PostgresOperator(
        task_id='card_type_effectiveness',
        postgres_conn_id='dwh_conn',
        sql="""
        INSERT INTO analysis.card_type_fraud_effectiveness
        SELECT 
            CURRENT_DATE as analysis_date,
            ct.card_type,
            ct.currency,
            ct.max_limit,
            COALESCE(f_alerts.total_alerts, 0) as total_alerts,
            COALESCE(t_volume.total_transaction_volume, 0) as total_transaction_volume,
            CASE 
                WHEN COALESCE(t_volume.total_transaction_volume, 0) > 0 
                    THEN COALESCE(f_alerts.total_alerts, 0)::DECIMAL / t_volume.total_transaction_volume
                ELSE 0 
            END as fraud_to_transaction_ratio,
            COALESCE(f_alerts.avg_fraud_amount, 0) as avg_fraud_amount,
            COALESCE(f_alerts.max_fraud_amount, 0) as max_fraud_amount,
            CASE 
                WHEN COALESCE(f_alerts.total_alerts, 0) > 0 THEN 
                    COALESCE(f_alerts.high_risk_alerts, 0)::DECIMAL / f_alerts.total_alerts
                ELSE 0 
            END as high_risk_ratio
        FROM public.card_types ct
        LEFT JOIN (
            SELECT 
                cd.card_type_id,
                COUNT(f.alert_id) as total_alerts,
                AVG(f.amount) as avg_fraud_amount,
                MAX(f.amount) as max_fraud_amount,
                COUNT(CASE WHEN f.alert_level = 'high' THEN 1 END) as high_risk_alerts
            FROM public.fraud_alerts f
            JOIN public.cards cd ON f.card_id = cd.id
            WHERE f.transaction_date >= CURRENT_TIMESTAMP - INTERVAL '1 day' + INTERVAL '3 hours'
              AND f.transaction_date < CURRENT_TIMESTAMP + INTERVAL '3 hours'
            GROUP BY cd.card_type_id
        ) f_alerts ON ct.id = f_alerts.card_type_id
        LEFT JOIN (
            SELECT 
                cd.card_type_id,
                COUNT(t.id) as total_transaction_volume
            FROM public.transactions t
            JOIN public.cards cd ON t.card_id = cd.id
            WHERE t.transaction_date >= CURRENT_TIMESTAMP - INTERVAL '1 day' + INTERVAL '3 hours'
              AND t.transaction_date < CURRENT_TIMESTAMP + INTERVAL '3 hours'
            GROUP BY cd.card_type_id
        ) t_volume ON ct.id = t_volume.card_type_id
        ORDER BY fraud_to_transaction_ratio DESC;
        """
    )

    card_type_effectiveness_task