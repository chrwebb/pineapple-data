import time
import requests
from bs4 import BeautifulSoup
from datetime import datetime
import os
import logging



now = datetime.now()
today = now.strftime("%Y%m%d")

url = 'https://nomads.ncep.noaa.gov/pub/data/nccf/com/nwm/prod/nwm.{}/medium_range_mem1/'.format(today)

save_path = "forecasts/nwm/nwm_data/"
#https://nomads.ncep.noaa.gov/pub/data/nccf/com/nwm/prod/nwm.20220915/medium_range_mem1/nwm.t00z.medium_range.land_1.f003.conus.nc


logger = logging.getLogger('forecasts')


def downloadlinks(elements, path):
    if not os.path.exists(path):
        os.makedirs(path)
    for element in elements:
        try:
            link = element.get('href')
            response = requests.get(url + link)
            open(path + element.text, "wb").write(response.content)
        except Exception as er:
            logger.error(str(er))



def process():
    #make folder
    now = datetime.now()
    dt_str = now.strftime("%Y_%m_%d_%H") + "/"
    path = save_path + dt_str
    if not os.path.exists(path):
        os.makedirs(path)
    path_0 = path + "00/"
    path_12 = path + "12/"
    try:
        page = requests.get(url)
        soup = BeautifulSoup(page.content, "html.parser")
        elemnts_00s = soup.find_all(lambda tag: tag.name == "a" and 'nwm.t00z.medium_range.land_1.f' in tag.text)
        elemnts_12s = soup.find_all(lambda tag: tag.name == "a" and 'nwm.t12z.medium_range.land_1.f' in tag.text)

        downloadlinks(elemnts_00s, path_0)
        downloadlinks(elemnts_12s, path_12)
    except Exception as er:
        logger.error(str(er))


