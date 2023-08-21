from datetime import datetime,timedelta
from airflow import DAG
from airflow.operators.bash  import BashOperator


default_args  = {
     'owner' : 'Abdulqadir Afolabi',
     'retries' : 5,
     'retry_dalay' : timedelta(minutes=2)
}
with DAG(
    dag_id = 'data2bot',
    default_args = default_args,
    description =  'data2bots',
    start_date =  datetime(2023, 4, 5,7),
    schedule_interval =  '@daily'
) as dag:
    task1 =  BashOperator(
        task_id = 'first_task',
        bash_command = ' cd /opt/airflow/dags/dbt_data2bots/abduafol4283_analytics && export DBT_PROFILES_DIR=/opt/airflow/dags/dbt_data2bots/.dbt  && pg_config --version && dbt run' 
    )


   
task1
