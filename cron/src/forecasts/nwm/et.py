import time
import requests
from bs4 import BeautifulSoup
from datetime import datetime
import os
import logging
import numpy as np



now = datetime.now()
today = now.strftime("%Y%m%d")

tz = "00"

url = 'https://nomads.ncep.noaa.gov/pub/data/nccf/com/nwm/prod/nwm.{}/forcing_medium_range/'.format(today)
save_path = "forecasts/nwm/nwm_data/"

logger = logging.getLogger('forecasts')


# ## the files are from 001 to 241 - so I had to make a list of numbers with leading zeros - the code below does that 
n =np.arange(1,5) ## to only download 2 days 
numbers = []

for i in n:
    numbers.append(str(i).zfill(3))


def downloadlinks(elements, path):
    if not os.path.exists(path):
        os.makedirs(path)
    for element in elements:
        try:
            link = element.get('href')
            response = requests.get(url + link)
            open(path + element.text, "wb").write(response.content)
            logger.debug('downloaded file: {}'.format(link))
        except Exception as er:
            logger.error(str(er))



def process():
    #make folder
    now = datetime.now()
    dt_str = now.strftime("%Y_%m_%d_%H") + "/"
    path = save_path + dt_str
    if not os.path.exists(path):
        os.makedirs(path)
    if tz == "00":
        path_0 = path + "00/"
        for i in numbers:
            try:
                page = requests.get(url)
                soup = BeautifulSoup(page.content, "html.parser")
                elemnts_00s = soup.find_all(lambda tag: tag.name == "a" and 'nwm.t00z' in tag.text and i in tag.text)

                downloadlinks(elemnts_00s, path_0)

            except Exception as er:
                logger.error(str(er))
    else:
        path_12 = path + "12/"
        for i in numbers:
            try:
                page = requests.get(url)
                soup = BeautifulSoup(page.content, "html.parser")
                elemnts_12s = soup.find_all(lambda tag: tag.name == "a" and 'nwm.t12z' in tag.text and i in tag.text)

                downloadlinks(elemnts_12s, path_12)

            except Exception as er:
                logger.error(str(er))


