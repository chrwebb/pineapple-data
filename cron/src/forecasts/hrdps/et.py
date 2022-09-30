import time
import requests
from bs4 import BeautifulSoup
from datetime import datetime
import os
import logging

url = 'https://dd.alpha.weather.gc.ca/model_hrdps/west/1km/grib2/'
nSub_folders = 5 ## for testing - we should make this 49 when doing the actual scraping 
save_path = "forecasts/hrdps/hrdps_data/"

logger = logging.getLogger('forecasts')


def downloadlinks(url, path):
	if not os.path.exists(path):
		os.makedirs(path)
	for i in range(nSub_folders):
		try:
			strSub = str(i)
			if i < 10:
				strSub = "0" + strSub
			cur_url = url + "0" + strSub + "/"
			page = requests.get(cur_url)
			soup = BeautifulSoup(page.content, "html.parser")
			element = soup.find(lambda tag: tag.name == "a" and 'PRES' in tag.text)
			link = element.get('href')
			response = requests.get(cur_url + link)
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
	path_0 = path + "00/"
	path_12 = path + "12/"

	downloadlinks(url + "00/", path_0)
	downloadlinks(url + "12/", path_12)

