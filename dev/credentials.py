from sqlalchemy import create_engine
import sqlalchemy
import urllib.parse
import os
from dotenv import load_dotenv

load_dotenv()  # load env variables

def db_conn():

    """

        This connects to a postgres DB using a .env file

        Parameters
        ----------
        conn_param : 
                POSTGRES_ADDRESS : link DB on cloud
                POSTGRES_PORT : port
                POSTGRES_USERNAME 
                POSTGRES_PASSWORD 
                POSTGRES_DBNAME 

           

        Returns
        -------
        posgres engine
        posgres connection 
    """
    POSTGRES_ADDRESS = str(os.getenv('POSTGRES_ADDRESS'))
    POSTGRES_PORT =str(os.getenv('POSTGRES_PORT')) 
    POSTGRES_USERNAME = str(os.getenv('POSTGRES_USERNAME'))
    POSTGRES_PASSWORD = urllib.parse.quote_plus(str(os.getenv('POSTGRES_PASSWORD')) )
    POSTGRES_DBNAME =  str(os.getenv('POSTGRES_DBNAME')) 

    conn_str = f'postgresql://{POSTGRES_USERNAME}:{POSTGRES_PASSWORD}@{POSTGRES_ADDRESS}:{POSTGRES_PORT}/{POSTGRES_DBNAME}'
    
    # create the connection to the database
    try:
        engine = create_engine(conn_str)
        conn = engine.connect().execution_options(stream_results=True)
    except (sqlalchemy.exc.DBAPIError,sqlalchemy.exc.InterfaceError) as err:
        print('database could not connect\n', err)
        engine = None
        conn = None
    finally:
        return engine,conn




    
