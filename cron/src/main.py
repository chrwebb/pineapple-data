from forecasts import processing
from utils.functions import setup_logging


setup_logging()

processing.hrdps_etl()

processing.nwm_etl()



# import requests
# import os
# from database import db

# try:
#     print("Querying db")
#     data = db.get_test()
#     print(f"DB result: {data}")
# except:
#     print("DB query failure")

# try:
#     print("Fetching URL")
#     r = requests.get(os.getenv('url'))
#     print(f"URL status code: {r.status_code}")
# except:
#     print("URL request failure")