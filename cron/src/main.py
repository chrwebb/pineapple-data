from forecasts import processing
from utils.functions import setup_logging
from database import db
from utils.functions import get_assets_id_and_geom
from utils.functions import get_sentinels_id_and_geom
from utils.functions import get_model_srtext
setup_logging()

# processing.hrdps_etl()

# processing.nwm_etl()

assets = get_assets_id_and_geom(db)
# print(assets.head())

sentinels = get_sentinels_id_and_geom(db)
# print(sentinels.head())

sr_text = get_model_srtext(db, "nwm")

processing.nwm_etl()

processing.nwm_transform(assets, sr_text)


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