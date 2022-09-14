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
		%(watershed_feature_id)s,
		%(month)s,
		%(unit_id)s,
		%(value)s
	)
"""

centroid_query = """
	SELECT
		watershed_feature_id,
		ST_X(ST_Centroid(geom4326)) as lon,
		ST_Y(ST_Centroid(geom4326)) as lat,
		ST_AsGeoJSON(geom4326)::json as geom4326
	FROM
		data.freshwater_atlas_upstream;
"""

centroid_point_query = """
	SELECT
		ST_Value(rast, %(x)s, %(y)s)
	FROm
		data.climate_normals_ppt{}
"""

area_query = """
	SELECT
		wfi.watershed_feature_id as watershed_feature_id,
		(ST_SummaryStats(ST_Clip(ppt.rast, ST_MakeValid(wfi.geom4326)))).mean as mean
	FROM
		data.freshwater_atlas_upstream wfi
	JOIN
		data.climate_normals_ppt{} ppt
	ON
		ST_Intersects(wfi.geom4326, ppt.rast)
	WHERE
		wfi.watershed_feature_id=%(wfi)s
"""

iter_cur.execute(centroid_query)

for i, location in enumerate(iter_cur):

	insert_dict_temp = {
		"watershed_feature_id": location['watershed_feature_id'], 
		"unit_id": 1
	}

	for b in range(1,13):
		cur.execute(area_query.format(b),{'wfi': location['watershed_feature_id']})
		value=cur.fetchall()[0]["mean"]

		if value==None:
			cur.execute(centroid_point_query,{'x': location['lon'], 'y': location['lat']})
			value=cur.fetchall()[0]["st_value"]
	
		insert_dict = insert_dict_temp
		insert_dict["month"] = b
		insert_dict["value"] = value

		cur.execute(insert_query, insert_dict)
