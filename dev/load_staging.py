from credentials import db_conn
from dotenv import load_dotenv
import os
import glob
import pandas as pd
import time

start_time = time.time()
## create db connections
source_engine, conn_source = db_conn()

## find all csv files

extension = 'csv'
os.chdir(os.getcwd())
result = glob.glob('*.{}'.format(extension))

## load files into db
for file in result:
    table_name = file.split('.')[0]
    dataset = pd.read_csv(file)
    dataset.to_sql(table_name, con=source_engine,schema = 'abduafol4283_staging' ,index=False, if_exists='replace')     
    print(f'{file} is done loading') 

end_time = time.time()
# Calculate the execution time
execution_time = end_time - start_time
print("Execution time:", execution_time, "seconds")