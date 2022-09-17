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

asset_query = """
	SELECT
		asset_id,
		watershed_feature_id
	FROM
		data.assets;
"""

centroid_query = """
	SELECT
		asset_id,
		ST_Value(rast, ST_Centroid(aoi_geom4326))
	FROM
		data.assets asset
	JOIN
		data.climate_normals_ppt{}
	ON
		ST_Intersects(ST_Centroid(aoi_geom4326), ppt.rast)
	WHERE
		asset.watershed_feature_id=%(watershed_feature_id)s;
"""

area_query = """
	SELECT
		(ST_SummaryStats(ST_Clip(ST_Union(ppt.rast), ST_MakeValid(aoi_geom4326)))).mean as mean
	FROM
		data.assets asset
	JOIN
		data.climate_normals_ppt{} ppt
	ON
		ST_Intersects(asset.aoi_geom4326, ppt.rast)
	WHERE
		asset.watershed_feature_id=%(watershed_feature_id)s
	GROUP BY
		asset.asset_id, asset.aoi_geom4326;
"""

iter_cur.execute(asset_query)
# iter_cur=[{'watershed_feature_id':8925604}]

for i, location in enumerate(iter_cur):

	insert_dict_temp = {
		"watershed_feature_id": location['watershed_feature_id'], 
		"unit_id": 1
	}

	for b in range(1,13):
		cur.execute(area_query.format(b),{'watershed_feature_id': location['watershed_feature_id']})
		value=cur.fetchall()[0]['mean']

		if value==None:
			cur.execute(centroid_point_query.format(b),{'x': location['lon'], 'y': location['lat']})
			value=cur.fetchall()[0]["st_value"]
	
		insert_dict = insert_dict_temp
		insert_dict["month"] = b
		insert_dict["value"] = value

		cur.execute(insert_query, insert_dict)

db_conn.commit()