import time
import requests
from bs4 import BeautifulSoup
from datetime import datetime
import os
import logging
import numpy as np
import pandas as pd
import geopandas as gpd 
import rioxarray
import xarray as xr
import h5netcdf
from netCDF4 import Dataset
from dask.diagnostics import ProgressBar
import glob, os
from shapely.geometry import mapping
import shapely
import warnings
from shapely.errors import ShapelyDeprecationWarning
warnings.filterwarnings("ignore", category=ShapelyDeprecationWarning) 



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

def tranform_asset_forecast(assets):
    # print(assets.head())

    path = 'forecasts/nwm/nwm_data/{}/00'.format(now.strftime("%Y_%m_%d_%H"))
    # print(path)

    glob_pattern = os.path.join(path, '*.nc' )

    try: 
        dsx = xr.open_mfdataset(glob_pattern, engine='h5netcdf',decode_times=True,combine ='by_coords').load()
        # print(dsx)
        dsx = dsx.rio.write_crs('esri:102001')

        logger.info('opening multiple netCDF files')
    except Exception as er:
        logger.error(str(er))

    results = []

    for index, row in assets.iterrows():
        print('asset: {}'.format(row['asset_id']))
        clipped = dsx.rio.clip(row['geom'],'esri:102001')
        df = clipped.to_dataframe()
        # print(df)
        df_final = df.groupby('time', as_index = True)['RAINRATE'].mean()*3600 ## to convert mm/s to mm/h 
        # print(df_final.values)
        asset_forecasts = pd.DataFrame()

        asset_forecasts['time'],asset_forecasts['rainfall']= [df_final.index,df_final.values]
        asset_forecasts['asset_id'] = row['asset_id']
        # print(asset_forecasts)
        results.append(asset_forecasts)

    results = pd.concat(results)
    # print(results)

    return results 



def tranform_sentinel_forecast(sentinels):
    # print(assets.head())

    path = 'forecasts/nwm/nwm_data/{}/00'.format(now.strftime("%Y_%m_%d_%H"))
    # print(path)

    glob_pattern = os.path.join(path, '*.nc' )

    try: 
        dsx = xr.open_mfdataset(glob_pattern, engine='h5netcdf',decode_times=True,combine ='by_coords').load()
        # print(dsx)
        dsx = dsx.rio.write_crs('esri:102001')

        logger.info('opening multiple netCDF files')
    except Exception as er:
        logger.error(str(er))

    results = []

    for index, row in assets.iterrows():
        print('asset: {}'.format(row['asset_id']))
        clipped = dsx.rio.clip(row['geom'],'esri:102001')
        df = clipped.to_dataframe()
        # print(df)
        df_final = df.groupby('time', as_index = True)['RAINRATE'].mean()*3600 ## to convert mm/s to mm/h 
        # print(df_final.values)
        asset_forecasts = pd.DataFrame()

        asset_forecasts['time'],asset_forecasts['rainfall']= [df_final.index,df_final.values]
        asset_forecasts['asset_id'] = row['asset_id']
        # print(asset_forecasts)
        results.append(asset_forecasts)

    results = pd.concat(results)
    # print(results)

    return results 