from osgeo import gdal
from datetime import datetime
import pdb
import psycopg2
import psycopg2.extras
import rioxarray
import os

dbname=os.environ.get("PGDATABASE")
user=os.environ.get("PGUSER")
host=os.environ.get("PGHOST")
password=os.environ.get("PGPASSWORD")
port=os.environ.get("PGPORT")

db_conn = psycopg2.connect("dbname='%s' user='%s' host='%s' password='%s' port='%s'" % (dbname, user, host, password, port))

iter_cur = db_conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
cur = db_conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

vrt = gdal.BuildVRT("./data/PPT.vrt",
	[
		"./data/PPT01.tif",
		"./data/PPT02.tif",
		"./data/PPT03.tif",
		"./data/PPT04.tif",
		"./data/PPT05.tif",
		"./data/PPT06.tif",
		"./data/PPT07.tif",
		"./data/PPT08.tif",
		"./data/PPT09.tif",
		"./data/PPT10.tif",
		"./data/PPT11.tif",
		"./data/PPT12.tif",		
	]
)

vrt = None

vrt = rioxarray.open_rasterio("./data/PPT.vrt")

insert_query = """
	INSERT INTO data.climate_normals_1991_2020 (
		watershed_feature_id,
		month,
		unit_id,
		value
	) VALUES (
		{watershed_feature_id},
		{month},
		{unit_id},
		{value}
	)
"""

centroid_query = """
	SELECT
		watershed_feature_id,
		ST_X(ST_transform(centroid,4326)) as lon,
		ST_Y(ST_transform(centroid,4326)) as lat
	FROM
		data.freshwater_atlas;
"""

iter_cur.execute(centroid_query)

for i, location in enumerate(iter_cur):

	location_vals = vrt.sel(x=location['lon'],y=location['lat'], method='nearest')
	insert_dict_temp = {
		"watershed_feature_id": location['watershed_feature_id'], 
		"unit_id": 1
	}

	for x in range(0, len(location_vals)):
		insert_dict = insert_dict_temp
		insert_dict["month"] = x+1
		insert_dict["value"] = location_vals[x].values.item()

		cur.execute(insert_query, insert_dict)
