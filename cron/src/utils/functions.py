## sendgrid email

## psycopg2 connection to server

## get all assets (geoms+id) for iteration elsewhere

## get all sentinels (geom+id) for iteration elsewehere

## insert record into forecast model table

import logging
import inspect
import os
log_file = os.path.abspath(os.path.join(os.path.dirname( __file__ ), '..', 'logs/app.log'))


def setup_logging():
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
