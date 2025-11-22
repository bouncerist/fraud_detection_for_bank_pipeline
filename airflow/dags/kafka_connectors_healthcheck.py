from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.utils.task_group import TaskGroup
from airflow.exceptions import AirflowException
from airflow.providers.http.hooks.http import HttpHook
from datetime import datetime, timedelta

default_args = {
    'owner': 'Gazetdinov Insaf',
    'retries': 1,
    'retry_delay': timedelta(minutes=2),
    'start_date': datetime(2025, 11, 11)
}

CONNECTORS = [
    "sink-clients", "sink-merchants", "sink-transactions", "sink-transactions-fraud",
    "sink-transaction_details", "src_dwh", "sink-card_types", "sink-cards"
]

def start_function():
    print("Начало проверки Kafka Connect коннекторов")
    return "started"

def end_function(**context):
    ti = context['ti']

    failed_connectors = []
    successful_connectors = []

    for connector in CONNECTORS:
        task_id = f"connector_checks.check_{connector.replace('-', '_')}"
        try:
            status = ti.xcom_pull(task_ids=task_id, key='return_value')
            print(f"DEBUG: Коннектор {connector} статус: {status}")
            if status == "SUCCESS":
                successful_connectors.append(connector)
            else:
                failed_connectors.append(connector)
        except Exception as e:
            print(f"Ошибка получения XCom для {connector}: {e}")
            failed_connectors.append(connector)

    print(f"Проверка завершена. Успешные: {successful_connectors}")

    if failed_connectors:
        error_msg = f"Упавшие коннекторы: {', '.join(failed_connectors)}"
        print(f"{error_msg}")
        raise AirflowException(error_msg)
    else:
        print("Все коннекторы работают нормально")
        return "completed"

def check_connector_status(connector_name):
    http_hook = HttpHook(http_conn_id="kafka_connect_api", method="GET")
    try:
        response = http_hook.run(endpoint=f"/connectors/{connector_name}/status")
        response.raise_for_status()

        data = response.json()
        connector_state = data["connector"]["state"]
        tasks_state = all(task["state"] == "RUNNING" for task in data["tasks"])

        if connector_state == "RUNNING" and tasks_state:
            print(f"Коннектор {connector_name} работает нормально")
            return "SUCCESS"
        else:
            error_msg = f"Коннектор {connector_name} имеет проблемы: connector={connector_state}, tasks={[t['state'] for t in data['tasks']]}"
            print(error_msg)
            return "FAILED"

    except Exception as e:
        print(f"Ошибка при проверке {connector_name}: {str(e)}")
        return "FAILED"

with DAG(
        'kafka_connect_health_check',
        default_args=default_args,
        description='Мониторинг состояния Kafka коннекторов',
        schedule_interval=timedelta(minutes=15),
        catchup=False,
        tags=['monitoring', 'kafka-connect', 'health check'],
        max_active_runs=1,
) as dag:

    start = PythonOperator(
        task_id='start',
        python_callable=start_function
    )

    with TaskGroup(group_id="connector_checks") as connector_checks_group:
        for connector in CONNECTORS:
            check_task = PythonOperator(
                task_id=f"check_{connector.replace('-', '_')}",
                python_callable=check_connector_status,
                op_kwargs={'connector_name': connector},
            )

    end = PythonOperator(
        task_id='end',
        python_callable=end_function,
        provide_context=True
    )

    start >> connector_checks_group >> end