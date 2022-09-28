import time
import requests
from bs4 import BeautifulSoup
from datetime import datetime
import os
import logging


logger = logging.getLogger(__name__)
## create console handler 
c_handler = logging.StreamHandler()
f_handler = logging.FileHandler('file.log')

## setting severity level
## if we use WARNING it will only log warning and higher levels 
## Debug, info, warning, error, critical - severity levels from low to high 
c_handler.setLevel(logging.WARNING)
f_handler.setLevel(logging.WARNING)

## creating formatter for each handler 
c_format = logging.Formatter('%(name)s - %(levelname)s - %(message)s')
f_format = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
## this means that format of console log and fole log are exactly the same
## except for the time log on the file 

## now we need to attach the formatting objects to each handler 

c_handler.setFormatter(c_format)
f_handler.setFormatter(f_format)

## now we need to link the handlers with formatter to our custom logger 
logger.addHandler(c_handler)
logger.addHandler(f_handler)



url = 'https://dd.alpha.weather.gc.ca/model_hrdps/west/1km/grib2/'
nSub_folders = 5 ## for testing - we should make this 49 when doing the actual scraping 
save_path = "scraped_hrdps_data/"



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
			logger.warning('downloaded file: {}'.format(link))
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
	downloadlinks(url + "00/", path_12)




process()

