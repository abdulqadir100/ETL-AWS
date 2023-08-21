# data2bots_accessement
data2bots_accessement

# 1. Prod Deployment Pipeline
## Pre_requisites

- **Python 3.8+** - see [this guide](https://docs.python-guide.org/starting/install3/win/) for instructions if you're on a windows. 
- **Requirement.txt** - see [this guide](https://note.nkmk.me/en/python-pip-install-requirements/) on running a requirement.txt file.
- **Airflow** - (required for orchestration. [Airflow Installation Guide](https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html)).
--Airflow was preferred to crontab for orchestration because it offers the ability to schedule, monitor, and most importantly, scale, increasingly complex workflows.
- **Docker** - (needed for contenarization). [Docker Installation Guide](https://docs.docker.com/engine/install/)).

## Architecture

### Extract and Load to Datawarehouse Staging
![alt text](https://github.com/abdulqadir100/data2bots_accessement/blob/main/architecture/Screenshot%202023-08-21%20at%2016.51.14.png)

### Transform from Datawarehouse Staging to Datawarehouse Analytics 
![alt text](https://github.com/abdulqadir100/data2bots_accessement/blob/main/architecture/TL.png)

