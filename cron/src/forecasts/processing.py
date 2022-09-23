from ecmwf import et as ecmwf_et
from hrdps import et as hrdps_et
from nwm import et as nwm_et
from utils import functions

## This should hold forecast agnostic functions for inserting forecast data into the db
## Calling a function here should call the relevant _et script, then recieve transformed, standardized records
## Records should be inserted into db