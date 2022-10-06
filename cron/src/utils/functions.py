## sendgrid email

## psycopg2 connection to server

## get all assets (geoms+id) for iteration elsewhere

## get all sentinels (geom+id) for iteration elsewehere

## insert record into forecast model table

import logging
import inspect
import os
import pandas as pd
import geopandas as gpd 
from sqlalchemy import create_engine 

db_connection_url = "***REMOVED***"
con = create_engine(db_connection_url) 

def setup_logging():
	log_file = os.path.abspath(os.path.join(os.path.dirname( __file__ ), '..', 'logs/app.log'))
	os.makedirs(os.path.abspath(os.path.join(os.path.dirname( __file__ ), '..', 'logs')),exist_ok =True )
	logger = logging.getLogger('forecasts')
	logger.setLevel(logging.DEBUG)
	fh = logging.FileHandler(log_file)
	fh.setLevel(logging.DEBUG)
	ch = logging.StreamHandler()
	ch.setLevel(logging.ERROR)
	formatter = logging.Formatter('%(asctime)s - %(name)s - %(pathname)s - %(funcName)s - %(levelname)s - %(message)s')
	fh.setFormatter(formatter)
	ch.setFormatter(formatter)
	logger.addHandler(fh)
	logger.addHandler(ch)


def get_assets_id_and_geom(db):

	query = """
	SELECT
		asset.asset_id,
		ST_Transform(asset.aoi_geom4326, (SELECT proj4text FROM spatial_ref_sys WHERE auth_name='nwm')) as geom
	FROM 
		data.assets asset
		"""

	# cursor = db.conn.cursor()
	# cursor.execute(query)

	# cols = [ i[0] for i in cursor.description]
	# assets = pd.DataFrame(cursor.fetchall(), columns = cols)

	assets = gpd.read_postgis(query,db.conn)
	return assets


def get_sentinels_id_and_geom(db):

	query = """
	SELECT
		sentinel.sentinel_id,
		ST_Transform(sentinel.geom4326, (SELECT proj4text FROM spatial_ref_sys WHERE auth_name='nwm')) as geom
	FROM 
		data.sentinels sentinel
		"""

	cursor = db.conn.cursor()
	cursor.execute(query)

	cols = [ i[0] for i in cursor.description]
	sentinels = pd.DataFrame(cursor.fetchall(), columns = cols)
	return sentinels

def get_model_srtext(db, model_name):

	query = """
		SELECT
			srtext
		FROM
			spatial_ref_sys
		WHERE
			auth_name=%(model_name)s;
	"""

	cursor = db.conn.cursor()
	cursor.execute(query, {'model_name':model_name})

	return cursor.fetchall()[0][0]