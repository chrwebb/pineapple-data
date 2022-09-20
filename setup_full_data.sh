#!/bin/bash

function main {
	# New data functions will need to be added to this list
	[ -z "$1" ] && { fire; road; freshwater_atlas; climate_normals; watershed_elevation; } || $1
}

function fire {
	bcdata bc2pg fire-perimeters-historical --db_url postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE --table fire_historical --schema staging
	bcdata bc2pg fire-perimeters-current --db_url postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE --table fire_current --schema staging
	psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/sql/populate_fire_table.sql
}

function road {
	bcdata bc2pg forest-tenure-road-section-lines --db_url postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE --table forest_roads --schema staging --promote_to_multi
	bcdata bc2pg digital-road-atlas-dra-master-partially-attributed-roads --db_url postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE --table road_atlas --schema staging --promote_to_multi
	psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/sql/populate_road_table.sql
}

function freshwater_atlas {
	unzip -qun data/test/fwa_4326.zip -d data/test/
	ogr2ogr -overwrite -f PostgreSQL PG:"host=$PGHOST user=$PGUSER dbname=$PGDATABASE" data/test/fwa_4326.geojson -dialect sqlite -nln data.freshwater_atlas_upstream -sql "select watershed_feature_id, Geometry as geom4326 from fwa_4326"
	rm data/test/fwa_4326.geojson

	# bcdata bc2pg freshwater-atlas-watersheds --db_url postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE --table freshwater_atlas --schema data
}

function watershed_elevation {
	wget https://pub.data.gov.bc.ca/datasets/175624/ -r -np -P data/
	find . -name "*.zip" | while read filename; do unzip -o -d "data/" "$filename"; done;
	gdal_merge.py -o data/dem_4269.tif data/*.dem
	gdalwarp -s_srs 4269 -t_srs 4326 data/dem_4269.tif data/dem_4326.tif
	raster2pgsql -d -C -s 4326 -t 100x100 ./data/dem_4326.tif data.dem_bc | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
	rm data/pub.data.gov.bc.ca -r
	rm data/dem*
}

function climate_normals {
	rm ./data/PPT*

	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT01.tif
	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT02.tif
	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT03.tif
	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT04.tif
	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT05.tif
	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT06.tif
	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT07.tif
	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT08.tif
	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT09.tif
	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT10.tif
	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT11.tif
	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT12.tif

	raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT01.tif data.climate_normals_ppt1 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
	raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT02.tif data.climate_normals_ppt2 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
	raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT03.tif data.climate_normals_ppt3 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
	raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT04.tif data.climate_normals_ppt4 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
	raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT05.tif data.climate_normals_ppt5 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
	raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT06.tif data.climate_normals_ppt6 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
	raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT07.tif data.climate_normals_ppt7 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
	raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT08.tif data.climate_normals_ppt8 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
	raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT09.tif data.climate_normals_ppt9 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
	raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT10.tif data.climate_normals_ppt10 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
	raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT11.tif data.climate_normals_ppt11 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
	raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT12.tif data.climate_normals_ppt12 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE

	rm ./data/PPT*

	python3 setup/python/watershed_centroid_precip.py
}

main "$@"