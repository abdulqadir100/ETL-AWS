FROM apache/airflow:2.5.3

USER root

RUN apt-get update \
    && apt-get install -y \
         wget \
          gnupg2 \
        python3-dev \
        libpq-dev \
        gcc \
        postgresql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER airflow


RUN  pip3 install --force-reinstall psycopg2==2.9.3

RUN pip install dbt-postgres
