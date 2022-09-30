# from ecmwf import et as ecmwf_et
from forecasts.hrdps import et as hrdps_et
# from nwm import et as nwm_et


## This should hold forecast agnostic functions for inserting forecast data into the db
## Calling a function here should call the relevant _et script, then recieve transformed, standardized records
## Records should be inserted into db

def hrdps_etl():
	hrdps_et.process()
